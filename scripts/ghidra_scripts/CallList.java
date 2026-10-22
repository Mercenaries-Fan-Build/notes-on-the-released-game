// The call list of a function's instructions, shared by FnMnemonicSig.java and ExportFunctions.java
// (not a script: Ghidra compiles this directory as one bundle, so both scripts see this class).
// FnMnemonicSig.java's header documents the call-list entries ("callees") and the two files this
// class reads: the ordinal table and the imports sidecar.
//
// Entries, in instruction order (duplicates kept): a direct call gives its target "0xADDR"; a call
// or branch to a sidecar function record gives "ext:<library>!<name>"; an import (Ghidra external
// space, or a thunk whose chain ends at an external function in a named library) gives
// "ext:<library>!<name>", an ordinal import named from the ordinal table; an indirect call with no
// flow gives "*0xSLOT", "*stack:<signed hex frame offset>" or "?"; a PS3 `sc` gives "sys:<N>".
// Every case the rules do not cover stops the script with a message naming the instruction.
import ghidra.program.flatapi.FlatProgramAPI;
import ghidra.program.model.address.Address;
import ghidra.program.model.lang.OperandType;
import ghidra.program.model.lang.Register;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Library;
import ghidra.program.model.listing.Program;
import ghidra.program.model.pcode.PcodeOp;
import ghidra.program.model.pcode.Varnode;
import ghidra.program.model.symbol.ExternalLocation;
import ghidra.program.model.symbol.RefType;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.Symbol;
import ghidra.program.model.symbol.SymbolUtilities;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CallList {
    private static final String IMPORTS_HEADER = "address\tkind\tlibrary\tordinal\tname";
    private static final String PRX_IMPORTS_HEADER = "address\tkind\tlibrary\tfnid\tname\tstub";
    // The last two words of an Xbox 360 import stub: mtctr r11; bctr.
    private static final int STUB_MTCTR = 0x7d6903a6;
    private static final int STUB_BCTR = 0x4e800420;
    private static final int STUB_SIZE = 16;
    // The PowerPC system call instruction with LEV 0.
    private static final int SC_WORD = 0x44000002;

    private final FlatProgramAPI api;
    private final Program currentProgram;
    private final String ordinalTablePath;
    private final boolean powerPc;

    // Export name per "<library>\t<ordinal>", from the ordinal table.
    private final Map<String, String> ordinalNames = new HashMap<>();

    // Sidecar records by address: "ext:<library>!<name>" per function record and per variable
    // record.
    private final Map<Long, String> stubImports = new HashMap<>();
    private final Map<Long, String> varImports = new HashMap<>();
    private long stubLo = 0, stubHi = 0;
    // Whether the sidecar is a PRX (PS3) imports sidecar.
    private boolean prxImports = false;

    // Loads the ordinal table at ordinalTablePath and the imports sidecar at imports ("-" for an
    // image with none) for api's current program. A program with no Ghidra external libraries
    // given "-", or with Ghidra external libraries given a sidecar, stops the script; so does a
    // PRX sidecar given to a program whose language has no register r11.
    public CallList(FlatProgramAPI api, String ordinalTablePath, String imports) throws Exception {
        this.api = api;
        this.currentProgram = api.getCurrentProgram();
        this.ordinalTablePath = ordinalTablePath;
        this.powerPc = currentProgram.getLanguage().getProcessor().toString().equals("PowerPC");
        loadOrdinalTable(ordinalTablePath);
        String[] extLibs = currentProgram.getExternalManager().getExternalLibraryNames();
        if (imports.equals("-")) {
            if (extLibs.length == 0) {
                throw new IllegalArgumentException(currentProgram.getName() + " has no external"
                    + " libraries and no imports sidecar was given (\"-\"); give its <id>.imports.tsv");
            }
        } else {
            if (extLibs.length > 0) {
                throw new IllegalArgumentException(currentProgram.getName() + " has external libraries "
                    + String.join(",", extLibs) + " and an imports sidecar " + imports
                    + " was given; give \"-\"");
            }
            loadImports(imports);
        }
        if (prxImports) {
            r11 = currentProgram.getRegister("r11");
            if (r11 == null) {
                throw new IllegalStateException(currentProgram.getName() + " was given a PRX imports"
                    + " sidecar but its language has no register r11");
            }
            r11Lo = r11.getAddress().getOffset();
            r11Hi = r11Lo + r11.getMinimumByteSize();
        }
    }

    // Whether the sidecar is a PRX (PS3) imports sidecar.
    public boolean isPrx() {
        return prxImports;
    }

    // Whether addr is the address of a sidecar function record (an import stub).
    public boolean isStubRecord(long addr) {
        return stubImports.containsKey(addr);
    }

    // The sidecar variable record at addr as "ext:<library>!<name>", or null.
    public String varImport(long addr) {
        return varImports.get(addr);
    }

    // The number of PS3 `sc` sites whose r11 was written on one path, and through joins.
    public int scOnePath() {
        return scOnePath;
    }

    public int scJoins() {
        return scJoins;
    }

    // Appends the call-list entries of instruction m of function f to callees and returns the
    // number of calls m counts: 1 for a call instruction and for a PS3 system call (`sc`), else 0.
    public int addCallees(Instruction m, Function f, List<String> callees) throws Exception {
        if (m.getFlowType().isCall()) {
            Address[] flows = m.getFlows();
            if (flows.length > 0) {
                for (Address t : flows) callees.add(flowCalleeText(m, t));
            } else {
                boolean slot = false;
                for (Reference r : m.getReferencesFrom()) {
                    if (r.getReferenceType().isData() || r.getReferenceType().isIndirect()) {
                        callees.add(slotText(m, r));
                        slot = true;
                    }
                }
                if (!slot) callees.add("?");
            }
            return 1;
        } else if (m.getFlowType().isJump()) {
            for (Address t : m.getFlows()) {
                if (inStubRange(t)) callees.add(stubText(m, t));
            }
        } else if (powerPc && m.getMnemonicString().equals("sc")) {
            if (!prxImports) {
                throw new IllegalStateException("sc at " + m.getAddress() + " in " + f.getName(true)
                    + ": the system call number register is known for a program given a PRX"
                    + " imports sidecar (PS3, r11) only");
            }
            callees.add("sys:" + syscallNumber(m, f));
            return 1;
        }
        return 0;
    }

    // Reads the imports sidecar at path into stubImports / varImports and sets the stub range.
    // The header line names the format. XEX: "address\tkind\tlibrary\tordinal\tname"; stops the
    // script, naming the file and line, on a row that is not "0x<8 hex>\t<function|variable>\t
    // <library>\t<decimal ordinal>\t<name>" (a name without whitespace), a repeated address, an
    // address outside the program's memory, or a function record whose bytes at +8 and +12 are not
    // mtctr r11; bctr. PRX: "address\tkind\tlibrary\tfnid\tname\tstub" (loadPrxImports). Any other
    // header stops the script.
    private void loadImports(String path) throws Exception {
        List<String> lines = Files.readAllLines(Paths.get(path), StandardCharsets.UTF_8);
        if (!lines.isEmpty() && lines.get(0).equals(PRX_IMPORTS_HEADER)) {
            loadPrxImports(path, lines);
            return;
        }
        if (lines.isEmpty() || !lines.get(0).equals(IMPORTS_HEADER)) {
            throw new IllegalArgumentException("imports sidecar " + path + ": header is neither '"
                + IMPORTS_HEADER.replace("\t", "\\t") + "' nor '"
                + PRX_IMPORTS_HEADER.replace("\t", "\\t") + "'");
        }
        long lo = Long.MAX_VALUE, hi = Long.MIN_VALUE;
        for (int i = 1; i < lines.size(); i++) {
            String line = lines.get(i);
            String where = path + ":" + (i + 1);
            String[] f = line.split("\t", -1);
            if (f.length != 5 || !f[0].matches("0x[0-9a-f]{8}")
                    || !(f[1].equals("function") || f[1].equals("variable"))
                    || f[2].isEmpty() || !f[3].matches("[0-9]+") || !f[4].matches("\\S+")) {
                throw new IllegalArgumentException("imports sidecar row " + where + " is not"
                    + " 0x<address>\\t<function|variable>\\t<library>\\t<ordinal>\\t<name>: '" + line + "'");
            }
            long addr = Long.parseLong(f[0].substring(2), 16);
            Address a = api.toAddr(addr);
            if (!currentProgram.getMemory().contains(a)) {
                throw new IllegalArgumentException("imports sidecar row " + where + ": " + f[0]
                    + " is not in " + currentProgram.getName() + "'s memory");
            }
            String text = "ext:" + f[2] + "!" + f[4];
            if (stubImports.containsKey(addr) || varImports.containsKey(addr)) {
                throw new IllegalArgumentException("imports sidecar row " + where + " repeats " + f[0]);
            }
            if (f[1].equals("function")) {
                int w2 = api.getInt(a.add(8)), w3 = api.getInt(a.add(12));
                if (w2 != STUB_MTCTR || w3 != STUB_BCTR) {
                    throw new IllegalArgumentException("imports sidecar row " + where + ": the stub at "
                        + f[0] + " ends " + String.format("%08x %08x", w2, w3)
                        + " in " + currentProgram.getName() + ", not mtctr r11; bctr");
                }
                stubImports.put(addr, text);
                lo = Math.min(lo, addr);
                hi = Math.max(hi, addr + STUB_SIZE);
            } else {
                varImports.put(addr, text);
            }
        }
        if (stubImports.isEmpty()) {
            throw new IllegalArgumentException("imports sidecar " + path + " has no function record");
        }
        stubLo = lo;
        stubHi = hi;
    }

    // Reads a PRX imports sidecar (header "address\tkind\tlibrary\tfnid\tname\tstub", one row per
    // PS3 function import: the code stub's address, "function", the library, the FNID as 8
    // lowercase hex digits, the function's name, and the stub's bytes as lowercase hex, whose
    // length is the stub size) into stubImports as "ext:<library>!<name>" and sets the stub range
    // from the lowest stub to the end of the highest. Stops the script, naming the file and line,
    // on a row that is not of that form (a name without whitespace), a repeated address, an address
    // outside the program's memory, or a stub whose bytes in the program are not the row's bytes.
    private void loadPrxImports(String path, List<String> lines) throws Exception {
        long lo = Long.MAX_VALUE, hi = Long.MIN_VALUE;
        for (int i = 1; i < lines.size(); i++) {
            String line = lines.get(i);
            String where = path + ":" + (i + 1);
            String[] f = line.split("\t", -1);
            if (f.length != 6 || !f[0].matches("0x[0-9a-f]{8}") || !f[1].equals("function")
                    || f[2].isEmpty() || !f[3].matches("[0-9a-f]{8}") || !f[4].matches("\\S+")
                    || !f[5].matches("([0-9a-f]{2})+")) {
                throw new IllegalArgumentException("imports sidecar row " + where + " is not"
                    + " 0x<address>\\tfunction\\t<library>\\t<8 hex fnid>\\t<name>\\t<hex stub bytes>: '" + line + "'");
            }
            long addr = Long.parseLong(f[0].substring(2), 16);
            Address a = api.toAddr(addr);
            if (!currentProgram.getMemory().contains(a)) {
                throw new IllegalArgumentException("imports sidecar row " + where + ": " + f[0]
                    + " is not in " + currentProgram.getName() + "'s memory");
            }
            if (stubImports.containsKey(addr)) {
                throw new IllegalArgumentException("imports sidecar row " + where + " repeats " + f[0]);
            }
            byte[] want = new byte[f[5].length() / 2];
            for (int k = 0; k < want.length; k++) {
                want[k] = (byte) Integer.parseInt(f[5].substring(2 * k, 2 * k + 2), 16);
            }
            byte[] got = api.getBytes(a, want.length);
            if (!java.util.Arrays.equals(got, want)) {
                throw new IllegalArgumentException("imports sidecar row " + where + ": the stub at "
                    + f[0] + " is " + hex(got) + " in " + currentProgram.getName() + ", not " + f[5]);
            }
            stubImports.put(addr, "ext:" + f[2] + "!" + f[4]);
            lo = Math.min(lo, addr);
            hi = Math.max(hi, addr + want.length);
        }
        if (stubImports.isEmpty()) {
            throw new IllegalArgumentException("imports sidecar " + path + " has no function record");
        }
        stubLo = lo;
        stubHi = hi;
        prxImports = true;
    }

    // r11, the register that holds the system call number at a PS3 `sc`.
    private Register r11;
    private long r11Lo, r11Hi;
    private int scOnePath = 0, scJoins = 0;

    // Whether any p-code op of ins writes a register range overlapping r11.
    private boolean writesR11(Instruction ins) {
        for (PcodeOp op : ins.getPcode()) {
            Varnode o = op.getOutput();
            if (o != null && o.isRegister() && o.getOffset() < r11Hi && o.getOffset() + o.getSize() > r11Lo) {
                return true;
            }
        }
        return false;
    }

    // The constant ins copies into r11 when its one write of r11 is a COPY of a constant into the
    // whole register ("li r11,N"); null for any other write.
    private Long constantR11(Instruction ins) {
        Long v = null;
        for (PcodeOp op : ins.getPcode()) {
            Varnode o = op.getOutput();
            if (o == null || !o.isRegister() || o.getOffset() >= r11Hi || o.getOffset() + o.getSize() <= r11Lo) continue;
            if (v != null || op.getOpcode() != PcodeOp.COPY || o.getOffset() != r11Lo
                    || o.getSize() != r11Hi - r11Lo || !op.getInput(0).isConstant()) {
                return null;
            }
            v = op.getInput(0).getOffset();
        }
        return v;
    }

    // The instructions control reaches i from, inside f: the instruction that falls through to i
    // and the source of every flow reference to i. Stops the script (naming the sc) when i is a
    // function entry, lies outside f's body, carries a reference that is not a flow from an
    // instruction (its address is taken, so control may arrive from code Ghidra does not show), or
    // has no known predecessor. Sets joined[0] when i has more than one predecessor.
    private List<Instruction> predecessors(Instruction sc, Function f, Instruction i, boolean[] joined) {
        Address a = i.getAddress();
        String site = "sc at " + sc.getAddress() + " in " + f.getName(true) + ": r11 is not provable: ";
        if (api.getFunctionAt(a) != null) {
            throw new IllegalStateException(site + "a path reaches the entry of " + api.getFunctionAt(a).getName(true)
                + " at " + a + " with no write of r11");
        }
        if (!f.getBody().contains(a)) {
            throw new IllegalStateException(site + "a path leaves the function body at " + a);
        }
        List<Instruction> out = new ArrayList<>();
        for (Reference r : api.getReferencesTo(a)) {
            Instruction from = api.getInstructionAt(r.getFromAddress());
            if (from == null || !r.getReferenceType().isFlow() || r.getReferenceType().isCall()) {
                throw new IllegalStateException(site + a + " is the target of a " + r.getReferenceType()
                    + " reference from " + r.getFromAddress() + ", not a branch from an instruction");
            }
            out.add(from);
        }
        Instruction prev = currentProgram.getListing().getInstructionContaining(a.subtract(1));
        if (prev != null && a.equals(prev.getFallThrough())) out.add(prev);
        if (out.isEmpty()) {
            throw new IllegalStateException(site + a + " has no fall-through predecessor and no branch to it");
        }
        if (out.size() > 1) joined[0] = true;
        return out;
    }

    // The system call number of the PS3 `sc` instruction sc in f: the value every path reaching sc
    // last wrote to r11, each such write being "li r11,N" (a COPY of a constant into r11). Walks
    // backwards from sc over predecessors (fall-through and Ghidra's flow references) inside f until
    // each path meets a write of r11. Stops the script, naming the sc, when sc is not the word
    // 0x44000002, a path meets any other write of r11, a call or another sc before a write of r11,
    // when predecessors stops, or when the paths' constants differ.
    private long syscallNumber(Instruction sc, Function f) throws Exception {
        String site = "sc at " + sc.getAddress() + " in " + f.getName(true) + ": r11 is not provable: ";
        if (sc.getInt(0) != SC_WORD) {
            throw new IllegalStateException("'" + sc + "' at " + sc.getAddress() + " is the word "
                + String.format("%08x", sc.getInt(0)) + ", not sc (" + String.format("%08x", SC_WORD) + ")");
        }
        boolean[] joined = {false};
        java.util.ArrayDeque<Instruction> work = new java.util.ArrayDeque<>(predecessors(sc, f, sc, joined));
        java.util.Set<Address> seen = new java.util.HashSet<>();
        java.util.TreeMap<Long, List<Address>> defs = new java.util.TreeMap<>();
        while (!work.isEmpty()) {
            Instruction p = work.pop();
            if (!seen.add(p.getAddress())) continue;
            if (writesR11(p)) {
                Long v = constantR11(p);
                if (v == null) {
                    throw new IllegalStateException(site + "'" + p + "' at " + p.getAddress()
                        + " writes r11 with something other than a constant");
                }
                defs.computeIfAbsent(v, k -> new ArrayList<>()).add(p.getAddress());
                continue;
            }
            if (p.getFlowType().isCall() || p.getMnemonicString().equals("sc")) {
                throw new IllegalStateException(site + "'" + p + "' at " + p.getAddress()
                    + " lies on a path before any write of r11");
            }
            work.addAll(predecessors(sc, f, p, joined));
        }
        if (defs.size() != 1) {
            throw new IllegalStateException(site + "the paths' last writes of r11 are " + defs);
        }
        if (joined[0]) scJoins++; else scOnePath++;
        return defs.firstKey();
    }

    public boolean inStubRange(Address t) {
        return t.isMemoryAddress() && t.getOffset() >= stubLo && t.getOffset() < stubHi;
    }

    // Callee text for a call or branch target t that is in the stub range: the function record's
    // "ext:<library>!<name>". Stops the script, naming the instruction and target, when t is on no
    // function record.
    private String stubText(Instruction ins, Address t) {
        String s = stubImports.get(t.getOffset());
        if (s == null) {
            throw new IllegalStateException("'" + ins + "' at " + ins.getAddress() + " targets "
                + t + ", inside the import stub range 0x" + Long.toHexString(stubLo) + "..0x"
                + Long.toHexString(stubHi) + " but on no function record");
        }
        return s;
    }

    // Signed hex of a stack frame offset: "-0x68", "0x10", "0x0".
    private static String signedHex(long v) {
        return v < 0 ? "-0x" + Long.toHexString(-v) : "0x" + Long.toHexString(v);
    }

    // Whether operand i of ins is a register ("call esp") or a memory operand with an index
    // register (two or more registers among its objects, "callf [esp+ebx*4+disp]").
    private static boolean registerOrIndexed(Instruction ins, int i) {
        if (i < 0 || i >= ins.getNumOperands()) return false;
        if (OperandType.isRegister(ins.getOperandType(i))) return true;
        int regs = 0;
        for (Object o : ins.getOpObjects(i)) {
            if (o instanceof Register) regs++;
        }
        return regs >= 2;
    }

    // Callee text for one data or indirect reference r of a call with no flow. Memory: "*0xSLOT"
    // (stops on a sidecar variable record); external: "*ext:..." as calleeText; stack READ:
    // "*stack:<signed hex offset>"; stack DATA on a register or index-register operand: "?". Stops
    // the script, naming the call, on any other stack reference and on any other address space.
    private String slotText(Instruction call, Reference r) {
        Address to = r.getToAddress();
        if (to.isMemoryAddress()) {
            if (varImports.containsKey(to.getOffset())) {
                throw new IllegalStateException("call '" + call + "' at " + call.getAddress()
                    + " reads its target from import variable " + varImports.get(to.getOffset())
                    + " at " + to + "; a call through an import variable is not handled");
            }
            return "*" + calleeText(call, to);
        }
        if (to.isExternalAddress()) return "*" + calleeText(call, to);
        if (to.isStackAddress()) {
            RefType rt = r.getReferenceType();
            if (rt == RefType.READ) return "*stack:" + signedHex(to.getOffset());
            if (rt == RefType.DATA && registerOrIndexed(call, r.getOperandIndex())) return "?";
            throw new IllegalStateException("call '" + call + "' at " + call.getAddress()
                + " carries a stack " + rt + " reference to " + to + " on operand "
                + r.getOperandIndex() + ", which is neither a READ nor a DATA reference on a"
                + " register or index-register operand");
        }
        throw new IllegalStateException("call '" + call + "' at " + call.getAddress()
            + " carries a " + r.getReferenceType() + " reference into address space '"
            + to.getAddressSpace().getName() + "' (" + to + "), which is not handled");
    }

    // Reads the ordinal table at path into ordinalNames. Stops the script, naming the file and
    // line, on a row that is not four tab-separated fields (non-empty library and name, a
    // non-negative decimal ordinal, a 64-hex-digit sha256) or that repeats a library and ordinal.
    private void loadOrdinalTable(String path) throws Exception {
        List<String> lines = Files.readAllLines(Paths.get(path), StandardCharsets.UTF_8);
        for (int i = 0; i < lines.size(); i++) {
            String line = lines.get(i);
            if (line.isEmpty() || line.startsWith("#")) continue;
            String where = path + ":" + (i + 1);
            String[] f = line.split("\t", -1);
            if (f.length != 4 || f[0].isEmpty() || f[2].isEmpty()
                    || !f[1].matches("[0-9]+") || !f[3].matches("[0-9a-f]{64}")) {
                throw new IllegalArgumentException("ordinal table row " + where + " is not"
                    + " <library>\\t<ordinal>\\t<name>\\t<sha256>: '" + line + "'");
            }
            String key = f[0] + "\t" + Integer.parseInt(f[1]);
            if (ordinalNames.put(key, f[2]) != null) {
                throw new IllegalArgumentException("ordinal table row " + where + " repeats "
                    + f[0] + " ordinal " + f[1]);
            }
        }
    }

    public static String hex(byte[] b) {
        StringBuilder sb = new StringBuilder(b.length * 2);
        for (byte x : b) sb.append(String.format("%02x", x & 0xff));
        return sb.toString();
    }

    public static String addrHex(Address a) {
        return String.format("0x%08x", a.getOffset());
    }

    // Callee text for a call target: "0xADDR" for a memory address; "ext:<library>!<name>" for an
    // address in external space (an imported function), from the external location's library name
    // and label. Stops the script, naming the call and target, when the external target has no
    // symbol, no external location, an empty label, or an empty or unknown ("<EXTERNAL>") library.
    private String calleeText(Instruction call, Address t) {
        if (!t.isExternalAddress()) return addrHex(t);
        Symbol sym = currentProgram.getSymbolTable().getPrimarySymbol(t);
        if (sym == null) {
            throw new IllegalStateException("call '" + call + "' at " + call.getAddress()
                + " targets external address " + t + " with no symbol");
        }
        ExternalLocation el = currentProgram.getExternalManager().getExternalLocation(sym);
        if (el == null) {
            throw new IllegalStateException("call '" + call + "' at " + call.getAddress()
                + " targets external address " + t + " (symbol '" + sym.getName(true)
                + "') with no external location");
        }
        return extText(call, t, el);
    }

    // Callee text for a direct call flow target: a target in the stub range gives stubText; a
    // sidecar variable record stops the script; a thunk function at t whose thunk chain ends at
    // an external function in a named library gives "ext:<library>!<name>" of that external
    // function; a thunk whose chain ends at an in-image function, or at an external function in
    // Ghidra's unknown library ("<EXTERNAL>"), gives the thunk's "0xADDR"; any other target gives
    // calleeText(call, t). Stops the script, naming the call and thunk, when the thunk has no
    // thunked function or the external function at the end of the chain has no external location.
    private String flowCalleeText(Instruction call, Address t) {
        if (!t.isMemoryAddress()) return calleeText(call, t);
        if (inStubRange(t)) return stubText(call, t);
        if (varImports.containsKey(t.getOffset())) {
            throw new IllegalStateException("call '" + call + "' at " + call.getAddress()
                + " targets import variable " + varImports.get(t.getOffset()) + " at " + t);
        }
        Function tf = currentProgram.getFunctionManager().getFunctionAt(t);
        if (tf == null || !tf.isThunk()) return calleeText(call, t);
        Function end = tf.getThunkedFunction(true);
        if (end == null) {
            throw new IllegalStateException("call '" + call + "' at " + call.getAddress()
                + " targets thunk " + tf.getName(true) + " at " + t + " with no thunked function");
        }
        if (!end.isExternal()) return addrHex(t);
        ExternalLocation el = end.getExternalLocation();
        if (el == null) {
            throw new IllegalStateException("call '" + call + "' at " + call.getAddress()
                + " targets thunk " + tf.getName(true) + " at " + t + " whose thunked external"
                + " function " + end.getName(true) + " has no external location");
        }
        if (Library.UNKNOWN.equals(el.getLibraryName())) return addrHex(t);
        return extText(call, t, el);
    }

    // "ext:<library>!<name>" for the external location el reached by the call to t. <name> is
    // the label, or for an ordinal label ("Ordinal_<n>") the ordinal table's name for the library
    // and ordinal. Stops the script, naming the call and target, on an empty label, an empty or
    // unknown ("<EXTERNAL>") library, or an ordinal label whose library and ordinal the table
    // does not name.
    private String extText(Instruction call, Address t, ExternalLocation el) {
        return extText("call '" + call + "' at " + call.getAddress() + " targets " + t, el);
    }

    // The thunk target of thunk function f (shared by ExportFunctions.java and GhidraBridge.java):
    // "0x%08x" of the thunked function's entry when it is in the image; for an external function,
    // "ext:<library>!<name>" (extText) when it is in a named library, and "0x%08x" of the external
    // location's address when it is in Ghidra's "<EXTERNAL>" library (a jump to an absolute
    // address outside the image, "EXT_FUN_<addr>"). A thunk with no thunked function, an external
    // function with no external location, and an "<EXTERNAL>" location with no address stop the
    // script.
    public String thunkTarget(Function f) {
        Address entry = f.getEntryPoint();
        Function t = f.getThunkedFunction(false);
        if (t == null) {
            throw new IllegalStateException("thunk " + f.getName(true) + " at " + entry
                + " has no thunked function");
        }
        if (!t.isExternal()) return addrHex(t.getEntryPoint());
        ExternalLocation el = t.getExternalLocation();
        if (el == null) {
            throw new IllegalStateException("thunk " + f.getName(true) + " at " + entry
                + " thunks external function " + t.getName(true) + " with no external location");
        }
        if (Library.UNKNOWN.equals(el.getLibraryName())) {
            Address ea = el.getAddress();
            if (ea == null) {
                throw new IllegalStateException("thunk " + f.getName(true) + " at " + entry
                    + " thunks " + t.getName(true) + " in library " + Library.UNKNOWN
                    + " with no address");
            }
            return addrHex(ea);
        }
        return extText("thunk " + f.getName(true) + " at " + entry + " thunks " + t.getName(true), el);
    }

    // "ext:<library>!<name>" for the external location el, as extText above; site names what
    // reaches el in the messages that stop the script.
    public String extText(String site, ExternalLocation el) {
        String lib = el.getLibraryName();
        String label = el.getLabel();
        if (lib == null || lib.isEmpty() || Library.UNKNOWN.equals(lib)
                || label == null || label.isEmpty()) {
            throw new IllegalStateException(site + " whose import has library '" + lib
                + "' and label '" + label + "'");
        }
        int ordinal = SymbolUtilities.getOrdinalValue(label);
        if (ordinal < 0) return "ext:" + lib + "!" + label;
        String name = ordinalNames.get(lib + "\t" + ordinal);
        if (name == null) {
            throw new IllegalStateException(site + ", import " + lib + " ordinal " + ordinal + " ('" + label
                + "'), which the ordinal table " + ordinalTablePath + " does not name");
        }
        return "ext:" + lib + "!" + name;
    }
}
