// Splice map: every place where the game's code block (.text) transfers control into the
// SecuROM-added blocks, and what the code it reaches there does.
//
// SecuROM replaced code in .text functions with a jmp/call into code it placed in its own blocks
// (Stext, .securom, ...). Most sites are a function entry whose only instruction is
// `JMP dword ptr [slot]`: the function's body was moved into a SecuROM block. For a patch, the
// moved code is what runs; the .text bytes after the jump never run.
//
// From each site the script follows the code Ghidra decodes in the SecuROM blocks: fall-through,
// both arms of every conditional jump, unconditional direct jumps, and calls (a call's target is
// recorded and the walk continues at Ghidra's fall-through for it). Calls are not entered. Each
// address is visited once per site. The walk records how every path ends:
//   rets        return instructions reached
//   to_code     addresses in the code block reached by a jump, fall-through or tail call
//   terminal    targets in the SecuROM blocks of calls Ghidra gives no fall-through, and of jumps
//               Ghidra models as tail calls (CALL_TERMINATOR)
//   imports     jumps through a memory slot that references an imported function, as
//               "<library>!<label>" (a tail jump into the import)
//   computed    other jumps with no direct target (register or memory operand), as "<addr>:<insn>"
//   undecoded   addresses whose bytes do not decode, as "<addr>:<first 16 bytes>"
//   data        addresses holding a defined data unit, as "<addr>:<type>"
//   leaves      flow targets outside the code block and the SecuROM blocks
//   overlap     flow targets inside an instruction already decoded at another address that has
//               references to it or a fall-through into it, as "<addr>:<host addr> <host insn>"
//               (Ghidra holds one instruction per byte)
//   redecoded   flow targets inside an instruction that nothing references and nothing falls
//               through into: that instruction is cleared and the target decoded, recorded as
//               "<addr>:<host addr> <host insn>"
// Where no instruction exists yet on a path, the script asks Ghidra's disassembler to decode it
// there (flow-following from that address); the program is opened read-only, so nothing is saved.
//
// outcome, derived from those columns in this order:
//   terminal    the code reaches at least one terminal call or tail call into the SecuROM blocks
//   unresolved  otherwise, some path ends at computed, undecoded, data, leaves or overlap
//   moved       otherwise: every path ends at a return, an import, or in the code block
//
// Args: <outPath> <codeBlock> <securomBlocks>
//   outPath        TSV written (must not exist)
//   codeBlock      name of the game's code block, e.g. .text
//   securomBlocks  comma-separated names of the SecuROM blocks, e.g. Stext,Sitext,Srdata,Sdata,.securom
// Every named block must exist and be executable; anything else stops the script.
// Output columns: site, site_insn, site_len, site_kind (jump|call), site_function (entry of the
// containing function, or -), at_entry (yes when site == site_function), target, target_block,
// outcome, insns (instructions walked), rets, to_code, terminal, computed, undecoded, data, leaves,
// overlap, redecoded, imports, callees (targets of the calls on the paths). List columns are ';'-separated, '-' when empty.
// The last line printed is "SpliceMap: <n> sites in <program>".
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.ExternalLocation;
import ghidra.program.model.symbol.ExternalReference;
import ghidra.program.model.symbol.FlowType;
import ghidra.program.model.symbol.Reference;
import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

public class SpliceMap extends GhidraScript {
    private static final String USAGE = "<outPath> <codeBlock> <securomBlocks>";
    private MemoryBlock code;
    private final List<MemoryBlock> sr = new ArrayList<>();

    private String requiredArg(int index) {
        String[] args = getScriptArgs();
        if (args.length <= index) {
            throw new IllegalArgumentException("missing script argument " + (index + 1)
                + "; usage: " + getClass().getSimpleName() + ".java " + USAGE);
        }
        return args[index];
    }

    private MemoryBlock execBlock(String name) {
        MemoryBlock b = currentProgram.getMemory().getBlock(name);
        if (b == null) {
            throw new IllegalArgumentException("no memory block named '" + name + "' in " + currentProgram.getName());
        }
        if (!b.isExecute()) {
            throw new IllegalArgumentException("memory block '" + name + "' is not executable");
        }
        return b;
    }

    private MemoryBlock srBlock(Address a) {
        for (MemoryBlock b : sr) if (b.contains(a)) return b;
        return null;
    }

    private static String hx(Address a) {
        return String.format("0x%08x", a.getOffset());
    }

    private String bytesAt(Address a, int n) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < n; i++) {
            try {
                sb.append(String.format("%02x", currentProgram.getMemory().getByte(a.add(i)) & 0xff));
            } catch (Exception e) {
                break;
            }
        }
        return sb.toString();
    }

    // The single direct flow target of an instruction, or null when it has none.
    private static Address soleFlow(Instruction ins) {
        Address[] f = ins.getFlows();
        if (f.length != 1) return null;
        return f[0];
    }

    // "<library>!<label>" when the computed jump m reads a memory slot that references an external
    // (imported) function, else null.
    private String importThrough(Instruction m) {
        for (Reference r : m.getReferencesFrom()) {
            Address slot = r.getToAddress();
            if (!slot.isMemoryAddress()) continue;
            for (Reference r2 : currentProgram.getReferenceManager().getReferencesFrom(slot)) {
                if (!r2.isExternalReference()) continue;
                ExternalLocation el = ((ExternalReference) r2).getExternalLocation();
                return el.getLibraryName() + "!" + el.getLabel();
            }
        }
        return null;
    }

    // True when the instruction just before host falls through into it.
    private boolean flowsInto(Instruction host) {
        Instruction prev = getInstructionBefore(host.getMinAddress());
        return prev != null && host.getMinAddress().equals(prev.getFallThrough());
    }

    private static String list(Set<String> s) {
        return s.isEmpty() ? "-" : String.join(";", s);
    }

    // Per-site walk state.
    private final class Walk {
        final Set<String> rets = new LinkedHashSet<>(), toCode = new LinkedHashSet<>(),
            terminal = new LinkedHashSet<>(), computed = new LinkedHashSet<>(),
            undecoded = new LinkedHashSet<>(), data = new LinkedHashSet<>(),
            leaves = new LinkedHashSet<>(), callees = new LinkedHashSet<>(),
            imports = new LinkedHashSet<>(), overlap = new LinkedHashSet<>(),
            redecoded = new LinkedHashSet<>();
        final Set<Address> seen = new HashSet<>();
        final Deque<Address> work = new ArrayDeque<>();
        int insns = 0;

        // A flow target: queued when it lies in a SecuROM block, otherwise recorded.
        void reach(Address a) {
            if (code.contains(a)) toCode.add(hx(a));
            else if (srBlock(a) == null) leaves.add(hx(a));
            else if (seen.add(a)) work.add(a);
        }

        void run(Address start) throws Exception {
            reach(start);
            while (!work.isEmpty()) {
                Address cur = work.poll();
                Instruction m = getInstructionAt(cur);
                if (m == null) {
                    Data d = getDataAt(cur);
                    if (d != null && d.isDefined()) {
                        data.add(hx(cur) + ":" + d.getDataType().getName());
                        continue;
                    }
                    Instruction host = getInstructionContaining(cur);
                    if (host != null) {
                        String h = hx(cur) + ":" + hx(host.getMinAddress()) + " " + host.toString();
                        if (currentProgram.getReferenceManager().getReferenceCountTo(host.getMinAddress()) > 0
                                || flowsInto(host)) {
                            overlap.add(h);
                            continue;
                        }
                        clearListing(host.getMinAddress(), host.getMaxAddress());
                        redecoded.add(h);
                    }
                    disassemble(cur);
                    m = getInstructionAt(cur);
                    if (m == null) {
                        undecoded.add(hx(cur) + ":" + bytesAt(cur, 16));
                        continue;
                    }
                }
                insns++;
                FlowType ft = m.getFlowType();
                if (ft.isCall()) {
                    Address c = soleFlow(m);
                    if (ft.isTerminal() || m.getFallThrough() == null) {
                        if (c == null) computed.add(hx(cur) + ":" + m.toString());
                        else if (srBlock(c) != null) terminal.add(hx(c));
                        else reach(c);
                    } else {
                        callees.add(c == null ? "?" : hx(c));
                        reach(m.getFallThrough());
                    }
                } else if (ft.isJump()) {
                    if (ft.isComputed() || m.getFlows().length == 0) {
                        String imp = importThrough(m);
                        if (imp != null) imports.add(imp);
                        else computed.add(hx(cur) + ":" + m.toString());
                    } else {
                        for (Address f : m.getFlows()) reach(f);
                    }
                    if (ft.isConditional() && m.getFallThrough() != null) reach(m.getFallThrough());
                } else if (ft.isTerminal()) {
                    rets.add(hx(cur));
                } else if (m.getFallThrough() != null) {
                    reach(m.getFallThrough());
                } else {
                    rets.add(hx(cur));
                }
            }
        }

        String outcome() {
            if (!terminal.isEmpty()) return "terminal";
            if (!computed.isEmpty() || !undecoded.isEmpty() || !data.isEmpty() || !leaves.isEmpty()
                || !overlap.isEmpty()) return "unresolved";
            return "moved";
        }
    }

    @Override
    public void run() throws Exception {
        File out = new File(requiredArg(0));
        if (out.exists()) {
            throw new IllegalArgumentException("output already exists: " + out);
        }
        code = execBlock(requiredArg(1));
        for (String n : requiredArg(2).split(",")) {
            MemoryBlock b = execBlock(n);
            if (b == code) throw new IllegalArgumentException("block '" + n + "' is the code block");
            sr.add(b);
        }

        PrintWriter pw = new PrintWriter(out, "UTF-8");
        pw.println("site\tsite_insn\tsite_len\tsite_kind\tsite_function\tat_entry\ttarget\ttarget_block"
            + "\toutcome\tinsns\trets\tto_code\tterminal\tcomputed\tundecoded\tdata\tleaves\toverlap\tredecoded"
            + "\timports\tcallees");
        int sites = 0;
        InstructionIterator it = currentProgram.getListing().getInstructions(code.getStart(), true);
        while (it.hasNext()) {
            Instruction ins = it.next();
            if (!code.contains(ins.getMinAddress())) break;
            FlowType ft = ins.getFlowType();
            if (!(ft.isJump() || ft.isCall())) continue;
            Address target = soleFlow(ins);
            if (target == null || srBlock(target) == null) continue;
            sites++;
            Function fn = getFunctionContaining(ins.getMinAddress());
            Walk w = new Walk();
            w.run(target);
            boolean atEntry = fn != null && fn.getEntryPoint().equals(ins.getMinAddress());
            pw.println(hx(ins.getMinAddress()) + "\t" + ins.toString().replace('\t', ' ') + "\t"
                + ins.getLength() + "\t" + (ft.isCall() ? "call" : "jump") + "\t"
                + (fn == null ? "-" : hx(fn.getEntryPoint())) + "\t" + (atEntry ? "yes" : "no") + "\t"
                + hx(target) + "\t" + srBlock(target).getName() + "\t" + w.outcome() + "\t" + w.insns
                + "\t" + list(w.rets) + "\t" + list(w.toCode) + "\t" + list(w.terminal) + "\t"
                + list(w.computed).replace('\t', ' ') + "\t" + list(w.undecoded) + "\t" + list(w.data)
                + "\t" + list(w.leaves) + "\t" + list(w.overlap).replace('\t', ' ') + "\t"
                + list(w.redecoded).replace('\t', ' ') + "\t"
                + list(w.imports) + "\t" + list(w.callees));
        }
        pw.close();
        println("SpliceMap: " + sites + " sites in " + currentProgram.getName());
    }
}
