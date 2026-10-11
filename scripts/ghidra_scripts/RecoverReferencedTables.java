// postScript: recover code reached only through pointer tables that instructions reference.
//
// Ghidra's "Create Address Tables" analyzer breaks a table at every referenced address and drops
// pieces shorter than its minimum table size, so short vtables (for example 4-entry Xbox 360 vtables
// that constructors reference one by one) are never typed and their targets never disassembled; and
// Ghidra's switch analysis leaves some jump tables unresolved. This script works at any table size.
//
// Candidates: every address that an instruction references with a data reference.
//
// Table run: the consecutive 4-byte big-endian words starting at a candidate in which each word points
// to valid code by PseudoDisassembler.isValidSubroutine(target, true). The run ends at the first word
// that is not such a pointer, at the next address that is a reference destination, at the end of the
// memory block, at an instruction, or at defined data that is neither undefined-typed nor
// pointer-typed (a CONFLICT ledger row; that word and the rest of the run are left as they are). A
// target covered by undefined-typed data is cleared before the validity check and recreated when the
// check fails or the table is not recovered.
//
// Each candidate is classified by how the instructions that reference it use it:
//
//   NOT POINTERS - every referencing instruction is a load of something other than a 4-byte integer
//     word (byte, halfword, float, doubleword or vector load). Nothing is changed.
//
//   SWITCH - from a referencing instruction, Ghidra's instruction flow (fall-through and branch
//     targets, staying inside the instruction's function and stopping at calls) leads through
//     register def-use to an indexed word load from the table, a `mtspr CTR` of the loaded register
//     and a non-linking `bctr` (the dispatcher). The indexed load is the referencing instruction itself
//     when it is an `lwzx`, an `lwzx` with the table register as an input, or an `lwz` through a
//     register that an `add` computed from the table register. Following a register stops at its
//     redefinition. The index stride is read from the instruction that defines the load's index
//     register, found through fall-from predecessors (`rlwinm` shift-left by n gives 2^n, `mulli`
//     gives its constant). A table with a dispatcher is a SWITCH when the stride is 4 (the entry size)
//     and no target is already a function entry.
//     Action: the words are typed as pointers, the targets are disassembled, and the dispatcher gets a
//     COMPUTED_JUMP mnemonic reference to every target (Instruction.addMnemonicReference with
//     SourceType.ANALYSIS, as Ghidra's DecompilerSwitchAnalysisCmd records switch cases). The
//     dispatching function's body is then recomputed with CreateFunctionCmd.fixupFunctionBody. No
//     function is created at a target.
//     A dispatcher in no function: its code start is where the fall-from chain from the bctr ends. When
//     a store instruction writes that start address (a reference on the store's operand 0), the start
//     is a proven function entry: a function is created there (logged as ENTRY with the store) and the
//     switch is recovered into it.
//
//   FUNCTION TABLE - a table with positive evidence of holding function pointers. Evidence kinds:
//     store        a referencing store whose reference is on operand 0 (the table address is stored);
//     rtti         a table word is an RTTI vtable slot (rtti sidecar);
//     bctrl        a table word loaded through the switch flow rule reaches mtspr CTR and a bctrl;
//     lwz          a referencing non-indexed word load (lwz / lwzu);
//     arg          the table address is written into r3-r10 by a referencing instruction and reaches a
//                  bl / bctrl through flow with no redefinition of that register;
//     loaded-arg   a referencing word load writes a table word into r3-r10 and it reaches a bl / bctrl
//                  through flow with no redefinition;
//     loaded-store a referencing word load's result is stored as a value (a store whose operand 0 is
//                  that register) through flow with no redefinition;
//     fp-variable  a referencing store writes into the table word (reference not on operand 0) and the
//                  word's initial target is already a function entry;
//     record-array a dispatcher with a stride other than 4 and a function at a target (indexed call
//                  through an array of records).
//     The words are typed as pointers, the targets are disassembled, and a function is created at each
//     target that is not already a function entry. A target inside another function's body gets no
//     function in that pass and is recorded; if it is still inside another function when a pass
//     changes nothing, the script fails.
//
// Forensic ledger: anything no rule classifies is written as one row to the ledger TSV and the script
// takes no action on it (nothing is typed, disassembled or created for it). Ledger kinds:
//   NO_EVIDENCE        a table with neither a switch dispatch nor function-table evidence;
//   STRIDE_FUNCTION    a dispatcher whose stride and the presence of a function at a target disagree
//                      (stride 4 with a function at a target, or another stride with none);
//   STRIDE_UNKNOWN     a dispatcher whose index stride cannot be determined;
//   FLOW_AMBIGUOUS     one referencing instruction reaches more than one bctr, or one bctr with two
//                      strides;
//   FLOW_UNHANDLED     a load or add on the table path that writes no single register;
//   SWITCH_NOFUNC      a dispatcher in no function whose code start has no proving store;
//   CONFLICT           a valid code pointer on a word covered by defined data of another type.
// Each row holds: pass, kind, table, word count, every referencing instruction (address, text, operand
// index and type of its reference to the table), the flow context, each target's state and the reason.
// The ledger holds the rows of the last pass. The closing line prints the ledger count per kind.
//
// The script repeats until a pass changes nothing, running auto-analysis on the changes after each
// pass, so tables referenced by newly recovered code are recovered too.
//
// Hard failures (IllegalStateException) only for internal errors: disassembly of a valid target
// producing no instruction, createFunction returning null, a created entry that does not contain its
// dispatcher, a dispatching function disappearing or a SWITCH target outside the dispatching function's
// body after the body fixup, a malformed rtti sidecar, a pass limit of 100, any exception from the
// listing; and a FUNCTION TABLE target still inside another function at the fixpoint.
//
// Args: <logFile> <rttiTsv> <ledgerTsv>
//   logFile   - every table with its evidence, entry, target, dispatcher and pass summary.
//   rttiTsv   - the image's rtti sidecar (`exemap` <id>.rtti.tsv, tab-separated, vtable and slot columns).
//   ledgerTsv - the forensic ledger.
// Run with the program writable (not -readOnly), before any export postScript.
//
// @category Mercs2
import ghidra.app.cmd.function.CreateFunctionCmd;
import ghidra.app.script.GhidraScript;
import ghidra.app.util.PseudoDisassembler;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSet;
import ghidra.program.model.data.DataType;
import ghidra.program.model.data.PointerDataType;
import ghidra.program.model.data.Undefined;
import ghidra.program.model.lang.Register;
import ghidra.program.model.listing.*;
import ghidra.program.model.mem.Memory;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.scalar.Scalar;
import ghidra.program.model.symbol.*;

import java.io.PrintWriter;
import java.nio.file.*;
import java.util.*;

public class RecoverReferencedTables extends GhidraScript {
    private static final String USAGE = "<logFile> <rttiTsv> <ledgerTsv>";
    private static final int MAX_PASSES = 100;
    private static final Set<String> ARG_REGISTERS = new HashSet<>(Arrays.asList(
        "r3", "r4", "r5", "r6", "r7", "r8", "r9", "r10"));

    private final Set<Long> rttiSlots = new HashSet<>();
    private PrintWriter log;
    private PseudoDisassembler pdis;
    private DataType ptrType;
    private Address clearedStart;
    private DataType clearedType;
    private boolean sawBctrl;
    private int pass;

    // per-pass counters and ledger
    private int tables, switchTables, functionTables, recordCallTables, notPointers, entries, pointersTyped,
            disassembled, functionsCreated, caseRefsAdded, bodiesFixed, entriesCreated;
    private final Map<Address, String> insidePending = new TreeMap<>();
    private final List<String> ledger = new ArrayList<>();
    private final Map<String, Integer> ledgerCounts = new TreeMap<>();

    /** A case no rule classifies; becomes a ledger row. */
    private static final class Unclassified extends Exception {
        final String kind;
        final String context;

        Unclassified(String kind, String reason, String context) {
            super(reason);
            this.kind = kind;
            this.context = context;
        }
    }

    private String requiredArg(int index) {
        String[] args = getScriptArgs();
        if (args.length <= index) {
            throw new IllegalArgumentException("missing script argument " + (index + 1)
                + "; usage: " + getClass().getSimpleName() + ".java " + USAGE);
        }
        return args[index];
    }

    @Override
    public void run() throws Exception {
        if (currentProgram.getDefaultPointerSize() != 4) {
            throw new IllegalStateException("only 4-byte pointers are handled; program pointer size is "
                + currentProgram.getDefaultPointerSize());
        }
        if (!currentProgram.getMemory().isBigEndian()) {
            throw new IllegalStateException("only big-endian programs are handled");
        }
        loadRtti(Paths.get(requiredArg(1)));
        Path ledgerPath = Paths.get(requiredArg(2));
        log = new PrintWriter(Files.newBufferedWriter(Paths.get(requiredArg(0))));
        pdis = new PseudoDisassembler(currentProgram);
        ptrType = PointerDataType.getPointer(null, 4);
        long totalTyped = 0, totalDis = 0, totalFn = 0, totalRefs = 0, totalBodies = 0, totalEntries = 0;
        try {
            for (pass = 1; ; pass++) {
                if (pass > MAX_PASSES) {
                    throw new IllegalStateException("no fixpoint after " + MAX_PASSES + " passes");
                }
                tables = switchTables = functionTables = recordCallTables = notPointers = entries = 0;
                pointersTyped = disassembled = functionsCreated = caseRefsAdded = bodiesFixed = entriesCreated = 0;
                insidePending.clear();
                ledger.clear();
                ledgerCounts.clear();
                TreeSet<Address> candidates = referencedAddresses();
                for (Address a : candidates) {
                    monitor.checkCancelled();
                    processCandidate(a);
                }
                int changes = pointersTyped + disassembled + functionsCreated + caseRefsAdded + bodiesFixed;
                String summary = "PASS " + pass + " candidates=" + candidates.size() + " tables=" + tables
                    + " switch=" + switchTables + " functionTables=" + functionTables + " recordCallTables="
                    + recordCallTables + " notPointers=" + notPointers + " entries=" + entries
                    + " pointersTyped=" + pointersTyped + " disassembled=" + disassembled
                    + " functionsCreated=" + functionsCreated + " entriesCreated=" + entriesCreated
                    + " caseRefsAdded=" + caseRefsAdded + " bodiesFixed=" + bodiesFixed
                    + " insidePending=" + insidePending.size() + " ledger=" + ledger.size() + " " + ledgerCounts;
                log.println(summary);
                println(summary);
                totalTyped += pointersTyped;
                totalDis += disassembled;
                totalFn += functionsCreated;
                totalRefs += caseRefsAdded;
                totalBodies += bodiesFixed;
                totalEntries += entriesCreated;
                if (changes == 0) {
                    writeLedger(ledgerPath);
                    if (!insidePending.isEmpty()) {
                        StringBuilder sb = new StringBuilder();
                        for (String d : insidePending.values()) {
                            sb.append("\n  ").append(d);
                        }
                        throw new IllegalStateException(insidePending.size()
                            + " function-table target(s) still inside another function at the fixpoint:" + sb);
                    }
                    break;
                }
                analyzeChanges(currentProgram);
            }
            String done = "RecoverReferencedTables: tables=" + tables + " switch=" + switchTables
                + " functionTables=" + functionTables + " recordCallTables=" + recordCallTables
                + " notPointers=" + notPointers + " pointersTyped=" + totalTyped + " disassembled=" + totalDis
                + " functionsCreated=" + totalFn + " entriesCreated=" + totalEntries + " caseRefsAdded="
                + totalRefs + " bodiesFixed=" + totalBodies + " ledger=" + ledger.size() + " " + ledgerCounts;
            log.println(done);
            println(done);
        }
        finally {
            log.close();
        }
    }

    private void writeLedger(Path path) throws Exception {
        try (PrintWriter w = new PrintWriter(Files.newBufferedWriter(path))) {
            w.println("pass\tkind\ttable\twords\tusers\tcontext\ttargets\treason");
            for (String row : ledger) {
                w.println(row);
            }
        }
    }

    private void addLedger(String kind, Address top, List<Address> words, List<Address> targets,
            List<Instruction> users, String context, String reason) {
        StringBuilder us = new StringBuilder();
        for (Instruction u : users) {
            us.append(u.getAddress()).append(" '").append(u).append('\'');
            for (Reference r : getReferencesFrom(u.getAddress())) {
                if (r.getToAddress().equals(top)) {
                    us.append(" op=").append(r.getOperandIndex()).append(' ').append(r.getReferenceType());
                }
            }
            us.append("; ");
        }
        StringBuilder ts = new StringBuilder();
        for (Address t : targets) {
            ts.append(t).append('=').append(targetState(t)).append("; ");
        }
        ledger.add(pass + "\t" + kind + "\t" + top + "\t" + words.size() + "\t" + clean(us.toString()) + "\t"
            + clean(context) + "\t" + clean(ts.toString()) + "\t" + clean(reason));
        ledgerCounts.merge(kind, 1, Integer::sum);
    }

    private static String clean(String s) {
        return s.replace('\t', ' ').replace('\n', ' ');
    }

    private String targetState(Address t) {
        Instruction i = getInstructionAt(t);
        String code = i != null ? "instruction" : (currentProgram.getListing().getDefinedDataContaining(t) != null
            ? "data" : (currentProgram.getListing().getInstructionContaining(t) != null ? "offcut" : "undefined"));
        Function f = getFunctionAt(t);
        if (f != null) {
            return code + ",function-entry";
        }
        Function c = getFunctionContaining(t);
        return code + (c == null ? ",no-function" : ",inside " + c.getEntryPoint());
    }

    /** Reads the rtti sidecar (tab-separated, header with "vtable" and "slot" columns). */
    private void loadRtti(Path path) throws Exception {
        List<String> lines = Files.readAllLines(path);
        if (lines.isEmpty()) {
            throw new IllegalStateException("rtti sidecar is empty: " + path);
        }
        List<String> hdr = Arrays.asList(lines.get(0).split("\t"));
        int vi = hdr.indexOf("vtable"), si = hdr.indexOf("slot");
        if (vi < 0 || si < 0) {
            throw new IllegalStateException("rtti sidecar " + path + " has no vtable/slot columns: " + lines.get(0));
        }
        for (int i = 1; i < lines.size(); i++) {
            String[] p = lines.get(i).split("\t");
            if (p.length <= Math.max(vi, si)) {
                throw new IllegalStateException("rtti sidecar " + path + " line " + (i + 1) + " is malformed");
            }
            rttiSlots.add(Long.decode(p[vi]) + 4L * Long.parseLong(p[si]));
        }
    }

    /** Every memory address that an instruction references with a data reference. */
    private TreeSet<Address> referencedAddresses() throws Exception {
        TreeSet<Address> set = new TreeSet<>();
        InstructionIterator it = currentProgram.getListing().getInstructions(true);
        while (it.hasNext()) {
            monitor.checkCancelled();
            for (Reference r : it.next().getReferencesFrom()) {
                if (r.getReferenceType().isData() && r.getToAddress().isMemoryAddress()) {
                    set.add(r.getToAddress());
                }
            }
        }
        return set;
    }

    private List<Instruction> referencingInstructions(Address top) {
        List<Instruction> users = new ArrayList<>();
        for (Reference r : getReferencesTo(top)) {
            if (!r.getReferenceType().isData()) {
                continue;
            }
            Instruction ins = getInstructionAt(r.getFromAddress());
            if (ins != null) {
                users.add(ins);
            }
        }
        return users;
    }

    private void processCandidate(Address top) throws Exception {
        if (top.getOffset() % 4 != 0) {
            return;
        }
        Memory mem = currentProgram.getMemory();
        MemoryBlock block = mem.getBlock(top);
        if (block == null || !block.isInitialized()) {
            return;
        }
        List<Instruction> users = referencingInstructions(top);
        if (users.isEmpty()) {
            return;
        }

        // the run of valid-code pointers (no listing change except the target-validity clearing)
        Listing listing = currentProgram.getListing();
        ReferenceManager refs = currentProgram.getReferenceManager();
        List<Address> words = new ArrayList<>();
        List<Address> targets = new ArrayList<>();
        List<Address> clearedTargets = new ArrayList<>();
        List<DataType> clearedTypes = new ArrayList<>();
        String end = null;
        for (Address e = top; ; e = e.add(4)) {
            if (!words.isEmpty() && refs.hasReferencesTo(e)) { end = "next referenced address " + e; break; }
            if (!block.contains(e) || !block.contains(e.add(3))) { end = "end of block at " + e; break; }
            AddressSet word = new AddressSet(e, e.add(3));
            if (listing.getInstructions(word, true).hasNext()
                    || listing.getInstructionContaining(e) != null) {
                end = "instruction at " + e;
                break;
            }
            Address target = toAddr(mem.getInt(e) & 0xffffffffL);
            if (!isValidTarget(target)) { end = "not a valid-code pointer at " + e; break; }
            Address cs = clearedStart;
            DataType ct = clearedType;
            clearedStart = null;
            clearedType = null;
            Data blocking = blockingData(e);
            if (blocking != null) {
                if (cs != null) {
                    createData(cs, ct);
                }
                addLedger("CONFLICT", top, Collections.singletonList(e), Collections.singletonList(target), users,
                    "word " + e + " covered by " + blocking.getDataType().getName() + " at " + blocking.getMinAddress(),
                    "valid code pointer on a word holding defined data of another type; the run ends here");
                end = "conflict at " + e;
                break;
            }
            if (cs != null) {
                clearedTargets.add(cs);
                clearedTypes.add(ct);
            }
            words.add(e);
            targets.add(target);
        }
        if (words.isEmpty()) {
            restoreCleared(clearedTargets, clearedTypes);
            return;
        }

        // NOT POINTERS: every referencing instruction is a load narrower or wider than a 4-byte word
        boolean allNonWordLoads = true;
        for (Instruction u : users) {
            if (!isNonWordLoad(u.getMnemonicString())) {
                allNonWordLoads = false;
                break;
            }
        }
        if (allNonWordLoads) {
            restoreCleared(clearedTargets, clearedTypes);
            notPointers++;
            log.println("NOTPOINTERS " + top + " words=" + words.size() + " users=" + describe(users));
            return;
        }

        try {
            classifyAndRecover(top, words, targets, end, users, clearedTargets, clearedTypes);
        }
        catch (Unclassified u) {
            restoreCleared(clearedTargets, clearedTypes);
            addLedger(u.kind, top, words, targets, users, u.context, u.getMessage());
        }
    }

    private void classifyAndRecover(Address top, List<Address> words, List<Address> targets, String end,
            List<Instruction> users, List<Address> clearedTargets, List<DataType> clearedTypes) throws Exception {
        // dispatchers found by flow from the referencing instructions; bctrl calls are noted on the way
        LinkedHashMap<Instruction, Long> dispatchers = new LinkedHashMap<>();
        List<String> bctrlEvidence = new ArrayList<>();
        for (Instruction u : users) {
            sawBctrl = false;
            Dispatch d = findDispatcher(u);
            if (sawBctrl) {
                bctrlEvidence.add("bctrl via " + u.getAddress());
            }
            if (d != null) {
                Long prev = dispatchers.put(d.bctr, d.stride);
                if (prev != null && !prev.equals(d.stride)) {
                    throw new Unclassified("FLOW_AMBIGUOUS", "dispatcher reached with two strides",
                        "dispatcher " + d.bctr.getAddress() + " strides " + prev + " and " + d.stride);
                }
            }
        }

        if (dispatchers.isEmpty()) {
            List<String> evidence = functionTableEvidence(top, words, targets, users);
            evidence.addAll(bctrlEvidence);
            if (evidence.isEmpty()) {
                throw new Unclassified("NO_EVIDENCE", "no switch dispatch and no function-table evidence",
                    flowContext(users));
            }
            tables++;
            entries += words.size();
            recoverFunctionTable(top, words, targets, end, users, " evidence: " + String.join("; ", evidence));
            return;
        }
        boolean stride4 = true;
        for (Long s : dispatchers.values()) {
            if (s != 4L) {
                stride4 = false;
            }
        }
        Address functionAtTarget = null;
        for (Address t : targets) {
            if (getFunctionAt(t) != null) {
                functionAtTarget = t;
                break;
            }
        }
        String dispDesc = describeDispatchers(dispatchers);
        if (stride4 && functionAtTarget == null) {
            recoverSwitch(top, words, targets, dispatchers.keySet(), end, users, clearedTargets, clearedTypes);
        }
        else if (!stride4 && functionAtTarget != null) {
            tables++;
            entries += words.size();
            recordCallTables++;
            recoverFunctionTable(top, words, targets, end, users,
                " evidence: record-array (" + dispDesc + "; function at target " + functionAtTarget + ")");
        }
        else {
            throw new Unclassified("STRIDE_FUNCTION", "stride and function presence disagree",
                "dispatch " + dispDesc + "; " + (functionAtTarget == null ? "no function at any target"
                    : "function at target " + functionAtTarget));
        }
    }

    /** The instructions following each referencing instruction, as context for a ledger row. */
    private String flowContext(List<Instruction> users) {
        StringBuilder ctx = new StringBuilder();
        for (Instruction u : users) {
            ctx.append("after ").append(u.getAddress()).append(": ");
            Instruction n = u;
            for (int k = 0; k < 6; k++) {
                n = getInstructionAfter(n);
                if (n == null) {
                    break;
                }
                ctx.append(n.getAddress()).append(" '").append(n).append("' ");
            }
            ctx.append("| ");
        }
        return ctx.toString();
    }

    /** Function-table evidence other than bctrl (collected by findDispatcher) and record-array. */
    private List<String> functionTableEvidence(Address top, List<Address> words, List<Address> targets,
            List<Instruction> users) throws Exception {
        List<String> ev = new ArrayList<>();
        for (Instruction u : users) {
            String m = u.getMnemonicString();
            if (m.startsWith("st")) {
                boolean value = false, into = false;
                for (Reference r : getReferencesFrom(u.getAddress())) {
                    if (r.getToAddress().equals(top)) {
                        if (r.getOperandIndex() == 0) {
                            value = true;
                        }
                        else {
                            into = true;
                        }
                    }
                }
                if (value) {
                    ev.add("store " + u.getAddress() + " '" + u + "'");
                }
                if (into && getFunctionAt(targets.get(0)) != null) {
                    ev.add("fp-variable " + u.getAddress() + " '" + u + "' (initial target " + targets.get(0)
                        + " is a function entry)");
                }
            }
            else if (m.equals("lwz") || m.equals("lwzu") || m.equals("lwzx")) {
                if (!m.equals("lwzx")) {
                    ev.add("lwz " + u.getAddress() + " '" + u + "'");
                }
                Register loaded = resultRegister(u);
                if (loaded != null) {
                    if (ARG_REGISTERS.contains(loaded.getName())) {
                        Instruction call = callReached(u, loaded);
                        if (call != null) {
                            ev.add("loaded-arg " + loaded.getName() + " " + u.getAddress() + " '" + u + "' -> "
                                + call.getAddress() + " '" + call + "'");
                        }
                    }
                    Instruction st = valueStoreReached(u, loaded);
                    if (st != null) {
                        ev.add("loaded-store " + u.getAddress() + " '" + u + "' -> " + st.getAddress() + " '" + st + "'");
                    }
                }
            }
            else if (!isLoad(m) && u.getFlowType().isFallthrough()) {
                Register r = resultRegister(u);
                if (r != null && ARG_REGISTERS.contains(r.getName())) {
                    Instruction call = callReached(u, r);
                    if (call != null) {
                        ev.add("arg " + r.getName() + " " + u.getAddress() + " '" + u + "' -> " + call.getAddress()
                            + " '" + call + "'");
                    }
                }
            }
        }
        for (Address w : words) {
            if (rttiSlots.contains(w.getOffset())) {
                ev.add("rtti slot " + w);
                break;
            }
        }
        return ev;
    }

    /** The first call (bl / bctrl) reached through flow from u while register r is not redefined. */
    private Instruction callReached(Instruction u, Register r) throws Exception {
        Function scope = getFunctionContaining(u.getAddress());
        Set<Address> seen = new HashSet<>();
        Deque<Instruction> work = new ArrayDeque<>(successors(u, scope));
        while (!work.isEmpty()) {
            monitor.checkCancelled();
            Instruction i = work.pop();
            if (!seen.add(i.getAddress())) {
                continue;
            }
            if (i.getFlowType().isCall()) {
                String m = i.getMnemonicString();
                if (m.equals("bl") || m.equals("bctrl")) {
                    return i;
                }
                continue;
            }
            if (writes(i, r)) {
                continue;
            }
            work.addAll(successors(i, scope));
        }
        return null;
    }

    /**
     * The first store reached through flow from u whose operand 0 (the stored value) is register r,
     * while r is not redefined and no call intervenes.
     */
    private Instruction valueStoreReached(Instruction u, Register r) throws Exception {
        Function scope = getFunctionContaining(u.getAddress());
        Set<Address> seen = new HashSet<>();
        Deque<Instruction> work = new ArrayDeque<>(successors(u, scope));
        while (!work.isEmpty()) {
            monitor.checkCancelled();
            Instruction i = work.pop();
            if (!seen.add(i.getAddress())) {
                continue;
            }
            if (i.getFlowType().isCall()) {
                continue;
            }
            if (i.getMnemonicString().startsWith("st")) {
                Object[] op0 = i.getOpObjects(0);
                if (op0.length == 1 && op0[0] instanceof Register && overlaps((Register) op0[0], r)) {
                    return i;
                }
            }
            if (writes(i, r)) {
                continue;
            }
            work.addAll(successors(i, scope));
        }
        return null;
    }

    /** A load of anything other than a 4-byte integer word: byte, halfword, float, doubleword, vector. */
    private static boolean isNonWordLoad(String mn) {
        return isLoad(mn) && !mn.startsWith("lwz") && !mn.startsWith("lwa") && !mn.equals("lwbrx")
            && !mn.equals("lwarx");
    }

    private String describeDispatchers(Map<Instruction, Long> dispatchers) {
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<Instruction, Long> e : dispatchers.entrySet()) {
            sb.append(e.getKey().getAddress()).append(" stride ").append(e.getValue()).append(' ');
        }
        return sb.toString().trim();
    }

    private void restoreCleared(List<Address> starts, List<DataType> types) throws Exception {
        for (int i = 0; i < starts.size(); i++) {
            createData(starts.get(i), types.get(i));
        }
        starts.clear();
        types.clear();
    }

    private String describe(List<Instruction> users) {
        StringBuilder sb = new StringBuilder();
        for (Instruction u : users) {
            sb.append(u.getAddress()).append(" '").append(u).append("'; ");
        }
        return sb.toString();
    }

    // ---- switch detection: flow + register def-use from a referencing instruction ----

    private enum Stage { TABLE_ADDR, LOADED, IN_CTR }

    private static final class State {
        final Instruction ins;
        final Stage stage;
        final Register reg;
        final boolean indexed;
        final Instruction load;
        final Register tableReg;

        State(Instruction ins, Stage stage, Register reg, boolean indexed, Instruction load, Register tableReg) {
            this.ins = ins;
            this.stage = stage;
            this.reg = reg;
            this.indexed = indexed;
            this.load = load;
            this.tableReg = tableReg;
        }

        State at(Instruction next) {
            return new State(next, stage, reg, indexed, load, tableReg);
        }

        String key() {
            return ins.getAddress() + "|" + stage + "|" + (reg == null ? "-" : reg.getName()) + "|" + indexed
                + "|" + (load == null ? "-" : load.getAddress().toString());
        }
    }

    private static final class Dispatch {
        final Instruction bctr;
        final long stride;

        Dispatch(Instruction bctr, long stride) {
            this.bctr = bctr;
            this.stride = stride;
        }
    }

    private static Register resultRegister(Instruction ins) {
        Register found = null;
        for (Object o : ins.getResultObjects()) {
            if (o instanceof Register) {
                Register r = (Register) o;
                if (r.isProcessorContext()) {
                    continue;
                }
                if (found != null && !found.equals(r)) {
                    return null;
                }
                found = r;
            }
        }
        return found;
    }

    private static boolean writes(Instruction ins, Register reg) {
        for (Object o : ins.getResultObjects()) {
            if (o instanceof Register && overlaps((Register) o, reg)) {
                return true;
            }
        }
        return false;
    }

    private static boolean reads(Instruction ins, Register reg) {
        for (Object o : ins.getInputObjects()) {
            if (o instanceof Register && overlaps((Register) o, reg)) {
                return true;
            }
        }
        return false;
    }

    private static boolean overlaps(Register a, Register b) {
        return a.getBaseRegister().equals(b.getBaseRegister());
    }

    /** PowerPC loads: mnemonics starting with "l" other than the immediate forms li / lis. */
    private static boolean isLoad(String mn) {
        return mn.startsWith("l") && !mn.equals("li") && !mn.equals("lis");
    }

    private static boolean writesCtr(Instruction ins) {
        for (Object o : ins.getResultObjects()) {
            if (o instanceof Register && ((Register) o).getName().equals("CTR")) {
                return true;
            }
        }
        return false;
    }

    /**
     * The non-linking bctr that dispatches through the table referenced by u, with the index stride,
     * or null. Sets sawBctrl when a loaded table word reaches a bctrl instead.
     */
    private Dispatch findDispatcher(Instruction u) throws Exception {
        Function scope = getFunctionContaining(u.getAddress());
        String m = u.getMnemonicString();
        State start;
        if (m.equals("lwzx")) {
            Register loaded = resultRegister(u);
            if (loaded == null) {
                throw new Unclassified("FLOW_UNHANDLED", "indexed load writes no single register",
                    "user " + u.getAddress() + " '" + u + "'");
            }
            start = new State(u, Stage.LOADED, loaded, true, u, null);
        }
        else if (isLoad(m) || m.startsWith("st") || !u.getFlowType().isFallthrough()) {
            return null;
        }
        else {
            Register addr = resultRegister(u);
            if (addr == null) {
                return null; // writes no register or several: not an address computation
            }
            start = new State(u, Stage.TABLE_ADDR, addr, false, null, addr);
        }

        Map<Instruction, Instruction> found = new LinkedHashMap<>(); // bctr -> indexed load
        Map<Instruction, Register> foundTableReg = new HashMap<>();
        Set<String> seen = new HashSet<>();
        Deque<State> work = new ArrayDeque<>();
        for (Instruction next : successors(u, scope)) {
            work.push(start.at(next));
        }
        while (!work.isEmpty()) {
            monitor.checkCancelled();
            State s = work.pop();
            if (!seen.add(s.key())) {
                continue;
            }
            Instruction ins = s.ins;
            if (s.stage == Stage.IN_CTR && ins.getMnemonicString().equals("bctrl")) {
                sawBctrl = true;
                continue;
            }
            if (ins.getFlowType().isCall()) {
                continue;
            }
            String mn = ins.getMnemonicString();
            State nextState = s;
            switch (s.stage) {
                case TABLE_ADDR:
                    if (reads(ins, s.reg) && (mn.equals("lwzx") || (mn.equals("lwz") && s.indexed))) {
                        Register loaded = resultRegister(ins);
                        if (loaded == null) {
                            throw new Unclassified("FLOW_UNHANDLED", "load on the table path writes no single register",
                                "user " + u.getAddress() + " load " + ins.getAddress() + " '" + ins + "'");
                        }
                        nextState = new State(ins, Stage.LOADED, loaded, true, ins, s.tableReg);
                    }
                    else if (reads(ins, s.reg) && mn.equals("add")) {
                        Register sum = resultRegister(ins);
                        if (sum == null) {
                            throw new Unclassified("FLOW_UNHANDLED", "add on the table path writes no single register",
                                "user " + u.getAddress() + " add " + ins.getAddress() + " '" + ins + "'");
                        }
                        if (!overlaps(sum, s.reg)) {
                            pushSuccessors(work, ins, scope, s);
                        }
                        nextState = new State(ins, Stage.TABLE_ADDR, sum, true, null, s.tableReg);
                    }
                    else if (writes(ins, s.reg)) {
                        continue;
                    }
                    break;
                case LOADED:
                    if (mn.equals("mtspr") && reads(ins, s.reg) && writesCtr(ins)) {
                        nextState = new State(ins, Stage.IN_CTR, null, true, s.load, s.tableReg);
                    }
                    else if (writes(ins, s.reg)) {
                        continue;
                    }
                    break;
                case IN_CTR:
                    if (mn.equals("bctr")) {
                        found.put(ins, s.load);
                        foundTableReg.put(ins, s.tableReg);
                        continue;
                    }
                    if (writesCtr(ins)) {
                        continue;
                    }
                    break;
            }
            pushSuccessors(work, ins, scope, nextState);
        }
        if (found.isEmpty()) {
            return null;
        }
        if (found.size() > 1) {
            StringBuilder sb = new StringBuilder();
            for (Instruction b : found.keySet()) {
                sb.append(b.getAddress()).append(' ');
            }
            throw new Unclassified("FLOW_AMBIGUOUS", "one referencing instruction reaches more than one bctr",
                "user " + u.getAddress() + " '" + u + "' reaches " + sb);
        }
        Instruction bctr = found.keySet().iterator().next();
        return new Dispatch(bctr, stride(found.get(bctr), foundTableReg.get(bctr), u));
    }

    /**
     * The index stride of an indexed load: among the load's input registers other than the table
     * register, exactly one must be defined (through fall-from predecessors) by `rlwinm` shift-left by n
     * (stride 2^n) or `mulli` (stride = its constant).
     */
    private long stride(Instruction load, Register tableReg, Instruction user) throws Unclassified {
        List<Long> scaled = new ArrayList<>();
        StringBuilder other = new StringBuilder();
        for (Object o : load.getInputObjects()) {
            if (!(o instanceof Register)) {
                continue;
            }
            Register r = (Register) o;
            if (tableReg != null && overlaps(r, tableReg)) {
                continue;
            }
            Instruction def = defThroughFallFrom(load, r);
            Long s = def == null ? null : scaleOf(def);
            if (s != null) {
                scaled.add(s);
            }
            else {
                other.append(r.getName()).append('=').append(def == null ? "no fall-from def" : "'" + def + "'").append(' ');
            }
        }
        if (scaled.size() != 1) {
            throw new Unclassified("STRIDE_UNKNOWN", "index stride cannot be determined",
                "load " + load.getAddress() + " '" + load + "' (user " + user.getAddress() + "): scaled=" + scaled
                    + " other=" + other);
        }
        return scaled.get(0);
    }

    private Instruction defThroughFallFrom(Instruction from, Register r) {
        Instruction cur = from;
        while (true) {
            Address ff = cur.getFallFrom();
            if (ff == null) {
                return null;
            }
            cur = getInstructionAt(ff);
            if (cur == null) {
                return null;
            }
            if (writes(cur, r)) {
                return cur;
            }
        }
    }

    private static Long scaleOf(Instruction def) {
        String m = def.getMnemonicString();
        if (m.equals("rlwinm")) {
            long sh = ((Scalar) def.getOpObjects(2)[0]).getValue();
            long mb = ((Scalar) def.getOpObjects(3)[0]).getValue();
            long me = ((Scalar) def.getOpObjects(4)[0]).getValue();
            if (mb == 0 && me == 31 - sh) {
                return 1L << sh;
            }
            return null;
        }
        if (m.equals("mulli")) {
            return ((Scalar) def.getOpObjects(2)[0]).getValue();
        }
        return null;
    }

    private void pushSuccessors(Deque<State> work, Instruction ins, Function scope, State s) {
        for (Instruction next : successors(ins, scope)) {
            work.push(s.at(next));
        }
    }

    /**
     * Flow successors of ins: the fall-through and the branch targets, kept only when they are
     * instructions inside the scope function (or, with no scope function, inside no function).
     */
    private List<Instruction> successors(Instruction ins, Function scope) {
        List<Instruction> out = new ArrayList<>();
        List<Address> addrs = new ArrayList<>();
        Address ft = ins.getFallThrough();
        if (ft != null) {
            addrs.add(ft);
        }
        if (ins.getFlowType().isJump() && !ins.getFlowType().isComputed()) {
            addrs.addAll(Arrays.asList(ins.getFlows()));
        }
        for (Address a : addrs) {
            Instruction n = getInstructionAt(a);
            if (n == null) {
                continue;
            }
            if (scope != null) {
                if (!scope.getBody().contains(a)) {
                    continue;
                }
            }
            else if (getFunctionContaining(a) != null) {
                continue;
            }
            out.add(n);
        }
        return out;
    }

    // ---- actions ----

    private void recoverSwitch(Address top, List<Address> words, List<Address> targets,
            Set<Instruction> dispatchers, String end, List<Instruction> users,
            List<Address> clearedTargets, List<DataType> clearedTypes) throws Exception {
        // a dispatcher in no function needs a proven entry before anything is changed
        Map<Instruction, Instruction> toCreate = new LinkedHashMap<>(); // entry -> proving store
        for (Instruction b : dispatchers) {
            if (getFunctionContaining(b.getAddress()) != null) {
                continue;
            }
            Instruction entry = b;
            while (entry.getFallFrom() != null) {
                Instruction prev = getInstructionAt(entry.getFallFrom());
                if (prev == null) {
                    break;
                }
                entry = prev;
            }
            Instruction proof = null;
            for (Reference r : getReferencesTo(entry.getAddress())) {
                Instruction from = getInstructionAt(r.getFromAddress());
                if (from != null && from.getMnemonicString().startsWith("st") && r.getOperandIndex() == 0) {
                    proof = from;
                    break;
                }
            }
            if (proof == null) {
                StringBuilder rf = new StringBuilder();
                for (Reference r : getReferencesTo(entry.getAddress())) {
                    rf.append(r.getFromAddress()).append(':').append(r.getReferenceType()).append(' ');
                }
                throw new Unclassified("SWITCH_NOFUNC", "dispatcher in no function and its code start has no proving store",
                    "dispatcher " + b.getAddress() + " code start " + entry.getAddress() + " references to start: "
                        + (rf.length() == 0 ? "none" : rf.toString()));
            }
            toCreate.put(entry, proof);
        }
        for (Map.Entry<Instruction, Instruction> e : toCreate.entrySet()) {
            Address entry = e.getKey().getAddress();
            Function f = createFunction(entry, null);
            if (f == null) {
                throw new IllegalStateException("createFunction failed at proven entry " + entry + " (table " + top + ")");
            }
            functionsCreated++;
            entriesCreated++;
            log.println("ENTRY " + entry + " created; address stored by " + e.getValue().getAddress() + " '"
                + e.getValue() + "'");
        }
        List<Function> owners = new ArrayList<>();
        for (Instruction b : dispatchers) {
            Function f = getFunctionContaining(b.getAddress());
            if (f == null) {
                throw new IllegalStateException("dispatcher " + b.getAddress() + " still in no function after its"
                    + " proven entry was created (table " + top + ")");
            }
            owners.add(f);
        }
        tables++;
        entries += words.size();
        switchTables++;
        StringBuilder sb = new StringBuilder();
        sb.append("SWITCH ").append(top).append(" entries=").append(words.size()).append(" end=").append(end)
            .append(" dispatchers=");
        for (Instruction b : dispatchers) {
            sb.append(b.getAddress()).append('@').append(getFunctionContaining(b.getAddress()).getEntryPoint()).append(' ');
        }
        log.println(sb);
        for (int i = 0; i < words.size(); i++) {
            Address e = words.get(i), t = targets.get(i);
            StringBuilder line = new StringBuilder("  " + e + " -> " + t);
            line.append(typePointer(e));
            line.append(ensureCode(t, e));
            for (Instruction b : dispatchers) {
                if (!hasRef(b.getAddress(), t)) {
                    b.addMnemonicReference(t, RefType.COMPUTED_JUMP, SourceType.ANALYSIS);
                    caseRefsAdded++;
                    line.append(" caseRef=added@").append(b.getAddress());
                }
                else {
                    line.append(" caseRef=existing@").append(b.getAddress());
                }
            }
            log.println(line);
        }
        for (Function f : owners) {
            AddressSet before = new AddressSet(f.getBody());
            CreateFunctionCmd.fixupFunctionBody(currentProgram, f, monitor);
            Function now = getFunctionAt(f.getEntryPoint());
            if (now == null) {
                throw new IllegalStateException("dispatching function " + f.getEntryPoint()
                    + " disappeared during body fixup (table " + top + ")");
            }
            if (!now.getBody().equals(before)) {
                bodiesFixed++;
                log.println("  body " + now.getEntryPoint() + " fixed: " + before.getNumAddresses() + " -> "
                    + now.getBody().getNumAddresses() + " bytes");
            }
        }
        for (Instruction b : dispatchers) {
            Function f = getFunctionContaining(b.getAddress());
            for (Address t : targets) {
                if (f == null || !f.getBody().contains(t)) {
                    Function other = getFunctionContaining(t);
                    throw new IllegalStateException("switch case " + t + " (table " + top + ", dispatcher "
                        + b.getAddress() + " in " + (f == null ? "no function" : f.getEntryPoint())
                        + ") is not in the dispatching function's body after fixupFunctionBody; it is in "
                        + (other == null ? "no function" : other.getEntryPoint()));
                }
            }
        }
    }

    private boolean hasRef(Address from, Address to) {
        for (Reference r : getReferencesFrom(from)) {
            if (r.getToAddress().equals(to)) {
                return true;
            }
        }
        return false;
    }

    private void recoverFunctionTable(Address top, List<Address> words, List<Address> targets, String end,
            List<Instruction> users, String note) throws Exception {
        functionTables++;
        log.println("TABLE " + top + " entries=" + words.size() + " end=" + end + note);
        for (int i = 0; i < words.size(); i++) {
            Address e = words.get(i), t = targets.get(i);
            StringBuilder line = new StringBuilder("  " + e + " -> " + t);
            line.append(typePointer(e));
            line.append(ensureCode(t, e));
            Function f = getFunctionAt(t);
            if (f != null) {
                line.append(" function=existing");
            }
            else {
                Function containing = getFunctionContaining(t);
                if (containing != null) {
                    insidePending.put(t, "target " + t + " (table " + top + " entry " + e + ") inside function "
                        + containing.getEntryPoint() + "; table users: " + describe(users));
                    line.append(" function=INSIDE ").append(containing.getEntryPoint());
                }
                else {
                    Function created = createFunction(t, null);
                    if (created == null) {
                        throw new IllegalStateException("createFunction failed at " + t + " (table entry " + e + ")");
                    }
                    functionsCreated++;
                    line.append(" function=created");
                }
            }
            log.println(line);
        }
    }

    private String typePointer(Address e) throws Exception {
        Listing listing = currentProgram.getListing();
        Data d = listing.getDefinedDataAt(e);
        if (d != null && d.isPointer() && d.getLength() == 4) {
            return " pointer=existing";
        }
        // blockingData() returned null, so every overlapping defined data is undefined-typed
        Data containing = listing.getDefinedDataContaining(e);
        if (containing != null) {
            clearListing(containing.getMinAddress(), containing.getMaxAddress());
        }
        DataIterator it = listing.getDefinedData(new AddressSet(e, e.add(3)), true);
        while (it.hasNext()) {
            Data o = it.next();
            clearListing(o.getMinAddress(), o.getMaxAddress());
        }
        createData(e, ptrType);
        pointersTyped++;
        return " pointer=typed";
    }

    private String ensureCode(Address t, Address e) throws Exception {
        if (getInstructionAt(t) != null) {
            return " code=existing";
        }
        if (!disassemble(t) || getInstructionAt(t) == null) {
            throw new IllegalStateException("disassembly produced no instruction at valid target " + t
                + " (table entry " + e + ")");
        }
        disassembled++;
        return " code=disassembled";
    }

    /**
     * The first defined data overlapping the word at e that is neither undefined-typed nor a 4-byte
     * pointer starting at e, or null when the word can be typed as a pointer.
     */
    private Data blockingData(Address e) {
        Listing listing = currentProgram.getListing();
        Data containing = listing.getDefinedDataContaining(e);
        if (containing != null && !isClearableOrPointerAt(containing, e)) {
            return containing;
        }
        DataIterator it = listing.getDefinedData(new AddressSet(e, e.add(3)), true);
        while (it.hasNext()) {
            Data d = it.next();
            if (!isClearableOrPointerAt(d, e)) {
                return d;
            }
        }
        return null;
    }

    private static boolean isClearableOrPointerAt(Data d, Address e) {
        if (d.getDataType() instanceof Undefined) {
            return true;
        }
        return d.isPointer() && d.getMinAddress().equals(e) && d.getLength() == 4;
    }

    /**
     * Valid code by isValidSubroutine; undefined-typed data at the target is cleared for the check
     * (and recreated when the check fails). A cleared-and-valid target is left in clearedStart /
     * clearedType so the caller can restore it if the table is not recovered.
     */
    private boolean isValidTarget(Address t) throws Exception {
        clearedStart = null;
        clearedType = null;
        if (t.getOffset() % 4 != 0 || !currentProgram.getMemory().contains(t)) {
            return false;
        }
        Listing listing = currentProgram.getListing();
        CodeUnit cu = listing.getCodeUnitContaining(t);
        if (cu instanceof Instruction) {
            return cu.getMinAddress().equals(t) && pdis.isValidSubroutine(t, true);
        }
        if (cu instanceof Data && ((Data) cu).isDefined()) {
            Data d = (Data) cu;
            if (!(d.getDataType() instanceof Undefined)) {
                return false;
            }
            Address start = d.getMinAddress();
            DataType dt = d.getDataType();
            clearListing(start, d.getMaxAddress());
            boolean valid = pdis.isValidSubroutine(t, true);
            if (!valid) {
                createData(start, dt);
            }
            else {
                clearedStart = start;
                clearedType = dt;
            }
            return valid;
        }
        return pdis.isValidSubroutine(t, true);
    }
}
