// Find and repair functions Ghidra marked non-returning although they return.
//
// A function marked non-returning ends every caller's flow at the call: the code after each call
// is not disassembled, the caller's body stops there and the decompiler writes
// "WARNING: Subroutine does not return". When the flag is wrong (e.g. the x87 sqrt/abs helpers of
// the PC builds, `fld; fsqrt; ...; ret`), every float-heavy caller is cut short.
//
// Modes:
//   report <outTsv>
//     Read-only. One row per non-external function marked non-returning: va, name, block, size,
//     thunk (yes/no), returns (instructions whose p-code holds a RETURN), push_returns (those of
//     them preceded by `PUSH <constant>` — the push/ret jump idiom SecuROM uses, which is a jump,
//     not a return), call_sites (call references to the entry) and cut_sites (call sites with no
//     instruction right after the call). Nothing is decided: the rows are for review.
//   apply <listFile> <outTsv>
//     The program must be opened writable; the headless run saves it. <listFile> holds one hex VA
//     per line (no 0x prefix), each a reviewed `report` row. For each: the function must exist, be
//     marked non-returning and have a return that is not a push return, or the script stops before
//     changing anything. Then the flag is cleared, every call site is cleared and disassembled again
//     (so the flow continues after the call), and each function containing a call site gets its
//     body recomputed (CreateFunctionCmd.fixupFunctionBody). A call carrying the CALL_RETURN flow
//     override (analysis records the non-returning call on the instruction itself) has it reset to
//     NONE. While the flow stopped at the call, analysis could define data in the never-disassembled
//     bytes after it (an operand like `fld [0x00b977f8]` reads as a pointer); a returning call falls
//     into code, so when the fall-through is still blocked, the gap from the call to the next
//     instruction is cleared and disassembled from the fall-through — only when every defined unit in the
//     gap is a pointer or an undefined type; any other data type leaves the site cut, named in the
//     row. Finally the changed addresses are auto-analysed (GhidraScript.analyzeChanges), not the
//     whole program, with the "Non-Returning Functions - Discovered" analyzer disabled for that
//     analysis (it is what marks these functions in the first place; its setting is restored
//     after), and a function marked non-returning again stops the script. One row per call site:
//     callee, site, caller (or -), cut_before (yes/no), cut_after (yes/no), caller_size_before,
//     caller_size_after, after_call (what the listing holds right after the call once the site is
//     disassembled again: instruction, data <type> at <va>, inside the instruction at <va>, or
//     undefined), override_reset (yes/no), gap_cleared (the data units cleared from the gap, as
//     <type>@<va> separated by ';', or -). A site still cut after the repair stops the script after
//     every row is
//     written. A caller that is itself marked non-returning is not changed here; run `report`
//     again to review it.
// <outTsv> must not exist. The last line printed is "RepairFalseNoReturn: ...".
// @category Mercs2
import ghidra.app.cmd.function.CreateFunctionCmd;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.FlowOverride;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.listing.Listing;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.pcode.PcodeOp;
import ghidra.program.model.scalar.Scalar;
import ghidra.program.model.symbol.Reference;
import java.io.File;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class RepairFalseNoReturn extends GhidraScript {
    private static final String USAGE = "report <outTsv> | apply <listFile> <outTsv>";

    private String requiredArg(int index) {
        String[] args = getScriptArgs();
        if (args.length <= index) {
            throw new IllegalArgumentException("missing script argument " + (index + 1)
                + "; usage: " + getClass().getSimpleName() + ".java " + USAGE);
        }
        return args[index];
    }

    private File newOutput(String path) {
        File out = new File(path);
        if (out.exists()) throw new IllegalArgumentException("output already exists: " + out);
        return out;
    }

    private static boolean isReturn(Instruction ins) {
        for (PcodeOp op : ins.getPcode()) if (op.getOpcode() == PcodeOp.RETURN) return true;
        return false;
    }

    // `PUSH <constant>` immediately before the return: the push/ret jump idiom.
    private boolean isPushReturn(Instruction ins) {
        Instruction prev = currentProgram.getListing().getInstructionBefore(ins.getAddress());
        if (prev == null || !prev.getMaxAddress().next().equals(ins.getAddress())) return false;
        if (!"PUSH".equalsIgnoreCase(prev.getMnemonicString()) || prev.getNumOperands() != 1) return false;
        Object[] objs = prev.getOpObjects(0);
        return objs.length == 1 && objs[0] instanceof Scalar;
    }

    private int[] returns(Function f) {
        int rets = 0, pushRets = 0;
        InstructionIterator it = currentProgram.getListing().getInstructions(f.getBody(), true);
        while (it.hasNext()) {
            Instruction ins = it.next();
            if (isReturn(ins)) {
                rets++;
                if (isPushReturn(ins)) pushRets++;
            }
        }
        return new int[] {rets, pushRets};
    }

    private List<Address> callSites(Function f) {
        List<Address> sites = new ArrayList<>();
        for (Reference r : getReferencesTo(f.getEntryPoint())) {
            if (r.getReferenceType().isCall()) sites.add(r.getFromAddress());
        }
        return sites;
    }

    // A call site whose next address holds no instruction: the flow stopped at the call.
    private boolean isCut(Address site) {
        Instruction call = getInstructionAt(site);
        if (call == null) return true;
        Address next = call.getMaxAddress().next();
        return next == null || getInstructionAt(next) == null;
    }

    // What the listing holds at `a`: an instruction, defined data (with its type), the middle of an
    // instruction or data unit (with its start), or nothing.
    private String describe(Address a) {
        if (a == null) return "end of the address space";
        Listing listing = currentProgram.getListing();
        if (listing.getInstructionAt(a) != null) return "instruction";
        Instruction in = listing.getInstructionContaining(a);
        if (in != null) return String.format("inside the instruction at 0x%08x", in.getMinAddress().getOffset());
        ghidra.program.model.listing.Data d = listing.getDefinedDataContaining(a);
        if (d != null) {
            return String.format("data %s at 0x%08x", d.getDataType().getName(), d.getMinAddress().getOffset());
        }
        return "undefined";
    }

    // The fall-through of the call at `site` is blocked: clear the gap from the call to the next
    // instruction when every defined unit in it is a pointer or an undefined type, then disassemble it
    // from the fall-through. Returns the units cleared (<type>@<va>;...), or "kept: <type>@<va>" naming the
    // first unit of another type (nothing is cleared then), or "-" when the gap holds no data.
    private String clearGapAfter(Address site) throws Exception {
        Listing listing = currentProgram.getListing();
        Instruction call = listing.getInstructionAt(site);
        if (call == null) return "-";
        Address start = call.getMaxAddress().next();
        Instruction nextIns = listing.getInstructionAfter(call.getMaxAddress());
        MemoryBlock block = currentProgram.getMemory().getBlock(start);
        if (start == null || block == null) return "-";
        Address end = nextIns != null && block.contains(nextIns.getMinAddress())
            ? nextIns.getMinAddress().previous() : block.getEnd();
        List<String> cleared = new ArrayList<>();
        ghidra.program.model.listing.DataIterator it = listing.getDefinedData(new ghidra.program.model.address.AddressSet(start, end), true);
        while (it.hasNext()) {
            ghidra.program.model.listing.Data d = it.next();
            ghidra.program.model.data.DataType dt = d.getDataType();
            boolean spurious = dt instanceof ghidra.program.model.data.Pointer
                || ghidra.program.model.data.Undefined.isUndefined(dt);
            String unit = String.format("%s@0x%08x", dt.getName(), d.getMinAddress().getOffset());
            if (!spurious) return "kept: " + unit;
            cleared.add(unit);
        }
        if (cleared.isEmpty()) return "-";
        clearListing(start, end);
        // From the fall-through itself: the call is already an instruction, which the disassembler
        // skips without following its flow.
        disassemble(start);
        return String.join(";", cleared);
    }

    // Ghidra's "Non-Returning Functions - Discovered" analyzer (FindNoReturnFunctionsAnalyzer) is what
    // marks these functions non-returning from call-site heuristics, sets CALL_RETURN on their calls
    // and clears the code after them; left enabled, analyzing the repaired code marks them again.
    // Its tasks are scheduled as code is defined, so it is disabled for the whole repair (from
    // before the first change through the analysis) and its setting restored afterwards; a program
    // whose analysis options lack it stops the script.
    private static final String NO_RETURN_DISCOVERY = "Non-Returning Functions - Discovered";

    private interface Work<T> {
        T run() throws Exception;
    }

    private <T> T withoutNoReturnDiscovery(Work<T> work) throws Exception {
        ghidra.framework.options.Options opts = currentProgram.getOptions(ghidra.program.model.listing.Program.ANALYSIS_PROPERTIES);
        if (!opts.contains(NO_RETURN_DISCOVERY)) {
            throw new IllegalStateException("analysis options have no '" + NO_RETURN_DISCOVERY + "' analyzer");
        }
        // The analysis manager caches each analyzer's enablement; initializeOptions re-reads it.
        ghidra.app.plugin.core.analysis.AutoAnalysisManager mgr =
            ghidra.app.plugin.core.analysis.AutoAnalysisManager.getAnalysisManager(currentProgram);
        boolean was = opts.getBoolean(NO_RETURN_DISCOVERY, true);
        opts.setBoolean(NO_RETURN_DISCOVERY, false);
        mgr.initializeOptions();
        try {
            return work.run();
        } finally {
            opts.setBoolean(NO_RETURN_DISCOVERY, was);
            mgr.initializeOptions();
        }
    }

    private String blockOf(Address a) {
        MemoryBlock b = currentProgram.getMemory().getBlock(a);
        return b == null ? "-" : b.getName();
    }

    private void report(File out) throws Exception {
        int n = 0, withReturns = 0;
        try (PrintWriter w = new PrintWriter(out, "UTF-8")) {
            w.println("va\tname\tblock\tsize\tthunk\treturns\tpush_returns\tcall_sites\tcut_sites");
            for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
                if (monitor.isCancelled()) throw new IllegalStateException("cancelled");
                if (!f.hasNoReturn()) continue;
                int[] r = returns(f);
                List<Address> sites = callSites(f);
                int cut = 0;
                for (Address s : sites) if (isCut(s)) cut++;
                w.println(String.format("0x%08x\t%s\t%s\t%d\t%s\t%d\t%d\t%d\t%d",
                    f.getEntryPoint().getOffset(), f.getName(true), blockOf(f.getEntryPoint()),
                    f.getBody().getNumAddresses(), f.isThunk() ? "yes" : "no", r[0], r[1], sites.size(), cut));
                n++;
                if (r[0] > r[1]) withReturns++;
            }
            if (w.checkError()) throw new IllegalStateException("writing " + out + " failed");
        }
        println("RepairFalseNoReturn: " + n + " non-returning functions, " + withReturns
            + " with a return that is not a push return -> " + out);
    }

    private void apply(String listPath, File out) throws Exception {
        Map<Address, Function> fns = new LinkedHashMap<>();
        List<String> lines = Files.readAllLines(Paths.get(listPath));
        for (int ln = 0; ln < lines.size(); ln++) {
            String line = lines.get(ln).trim();
            if (line.isEmpty()) continue;
            long va;
            try {
                va = Long.parseLong(line, 16);
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException(listPath + " line " + (ln + 1) + ": '" + line + "' is not a hex VA");
            }
            Address a = toAddr(va);
            Function f = getFunctionAt(a);
            if (f == null) throw new IllegalArgumentException(listPath + " line " + (ln + 1) + ": no function at " + a);
            if (!f.hasNoReturn()) throw new IllegalArgumentException(listPath + " line " + (ln + 1) + ": " + f.getName() + " is not marked non-returning");
            int[] r = returns(f);
            if (r[0] <= r[1]) {
                throw new IllegalArgumentException(listPath + " line " + (ln + 1) + ": " + f.getName()
                    + " has no return other than push returns (" + r[0] + " returns, " + r[1] + " push returns)");
            }
            fns.put(a, f);
        }
        int[] counts = withoutNoReturnDiscovery(() -> repairSites(fns, out));
        for (Function f : fns.values()) {
            if (f.hasNoReturn()) {
                throw new IllegalStateException(f.getName() + " is marked non-returning again after analysis");
            }
        }
        int sitesTotal = counts[0], stillCut = counts[1];
        println("RepairFalseNoReturn: cleared " + fns.size() + " functions, " + sitesTotal
            + " call sites re-disassembled, " + stillCut + " still cut -> " + out);
        if (stillCut > 0) {
            throw new IllegalStateException(stillCut + " call sites are still cut after the repair; see " + out);
        }
    }

    // Clear the flag of each function, repair every call site, write the rows; then analyse the
    // changed addresses. Returns {call sites, sites still cut}.
    private int[] repairSites(Map<Address, Function> fns, File out) throws Exception {
        Listing listing = currentProgram.getListing();
        int sitesTotal = 0, stillCut = 0;
        try (PrintWriter w = new PrintWriter(out, "UTF-8")) {
            w.println("callee\tsite\tcaller\tcut_before\tcut_after\tcaller_size_before\tcaller_size_after\tafter_call\toverride_reset\tgap_cleared");
            for (Function f : fns.values()) {
                f.setNoReturn(false);
                for (Address site : callSites(f)) {
                    Function caller = getFunctionContaining(site);
                    long before = caller == null ? -1 : caller.getBody().getNumAddresses();
                    boolean cutBefore = isCut(site);
                    Instruction call = listing.getInstructionAt(site);
                    boolean overrideReset = false;
                    if (call != null && call.getFlowOverride() == FlowOverride.CALL_RETURN) {
                        call.setFlowOverride(FlowOverride.NONE);
                        overrideReset = true;
                    }
                    if (call != null) clearListing(call.getMinAddress(), call.getMaxAddress());
                    disassemble(site);
                    String gapCleared = "-";
                    if (isCut(site)) gapCleared = clearGapAfter(site);
                    if (caller != null) CreateFunctionCmd.fixupFunctionBody(currentProgram, caller, monitor);
                    boolean cutAfter = isCut(site);
                    long after = caller == null ? -1 : caller.getBody().getNumAddresses();
                    if (cutAfter) stillCut++;
                    sitesTotal++;
                    Instruction again = listing.getInstructionAt(site);
                    String afterCall = again == null ? "no call instruction at the site" : describe(again.getMaxAddress().next());
                    w.println(String.format("0x%08x\t0x%08x\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s",
                        f.getEntryPoint().getOffset(), site.getOffset(),
                        caller == null ? "-" : String.format("0x%08x", caller.getEntryPoint().getOffset()),
                        cutBefore ? "yes" : "no", cutAfter ? "yes" : "no",
                        before < 0 ? "-" : Long.toString(before), after < 0 ? "-" : Long.toString(after), afterCall,
                        overrideReset ? "yes" : "no", gapCleared));
                }
            }
            if (w.checkError()) throw new IllegalStateException("writing " + out + " failed");
        }
        analyzeChanges(currentProgram);
        return new int[] {sitesTotal, stillCut};
    }

    @Override
    public void run() throws Exception {
        String mode = requiredArg(0);
        if ("report".equals(mode)) {
            report(newOutput(requiredArg(1)));
        } else if ("apply".equals(mode)) {
            apply(requiredArg(1), newOutput(requiredArg(2)));
        } else {
            throw new IllegalArgumentException("unknown mode '" + mode + "'; usage: " + getClass().getSimpleName() + ".java " + USAGE);
        }
    }
}
