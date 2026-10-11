// Per-function content signature for cross-build and cross-platform diffing. Builds place the
// same functions at different addresses, so a byte/address diff is meaningless. Instead signature
// each function in the named code blocks by its instruction-MNEMONIC sequence (invariant to
// addresses/immediates) plus its size and instruction count. Same code moved => identical
// mnemonic-sig; a patched function => changed sig. Run once per program (-process <name>) and diff
// the JSONs offline.
//
// Args: <outDir> <codeBlocks> <ordinalTable> <imports>  — <codeBlocks> is a comma-separated list
//   of executable memory block names (".text" for the PC images, ".text,BINK" for the Xbox 360
//   images); a name that is missing or not executable stops the script. <ordinalTable> is a
//   tab-separated file (pe_import_ordinals.tsv next to this script) of rows
//   "<library>\t<ordinal>\t<name>\t<source dll sha256>", '#' lines being comments; a malformed or
//   duplicate row stops the script. <imports> is the image's imports sidecar (`exemap imports`,
//   <id>.imports.tsv), or "-" for an image with none. Its header line names its format, and both
//   formats carry a name column: XEX (Xbox 360), "address\tkind\tlibrary\tordinal\tname": one row
//   per XEX import record, kind "function" for an import stub, "variable" for an import slot, and
//   the export's name; a function record whose bytes at +8 and +12 are not "mtctr r11; bctr" stops
//   the script, and a function record covers 16 bytes. PRX (PS3),
//   "address\tkind\tlibrary\tfnid\tname\tstub": one row per function import, kind "function", the
//   FNID as 8 lowercase hex digits, the function's name and the stub's bytes as lowercase hex; a
//   stub whose bytes in the program are not the row's stops the script, and a function record
//   covers as many bytes as the row gives. A sidecar whose header is neither, among them one
//   without the name column, stops the script. A program with no Ghidra external libraries given
//   "-", or with Ghidra external libraries given a sidecar, stops the script; so does a malformed
//   or duplicate sidecar row. The stub range runs from the lowest function record to the end of
//   the highest.
//   Import stub functions (an entry on a function record) are not written as keys; a function
//   entry in the stub range on no record stops the script. Writes <outDir>/fnsig_<programName>.json
//   => { "0xADDR": {...} } with fields:
//   sig     8-byte SHA-1 prefix (hex) of the mnemonic sequence "mov;push;call;..."
//   n       instruction count
//   sz      body size in bytes
//   calls   number of call instructions, counting each PS3 system call (`sc`)
//   callees call targets in instruction order (duplicates kept), followed in place by the target
//           of every branch to a sidecar function record (a tail jump) and by every PS3 `sc`. A
//           direct call gives its target "0xADDR"; a direct call or branch to a sidecar function
//           record gives "ext:<library>!<name>" from the record's library and name columns (XEX
//           and PRX). In a program given a PRX sidecar, each `sc` (the word 0x44000002) gives
//           "sys:<N>", N (decimal) the system call number in r11: walking backwards from the sc
//           over its predecessors in the function (the instruction falling through to it and the
//           source of each Ghidra flow reference to it), every path must meet "li r11,N" (a p-code
//           COPY of a constant into r11) with the same N. A path that meets any other write of
//           r11, a call or another sc first, reaches a function entry or leaves the function body,
//           or meets an instruction with no known predecessor or with a reference that is not a
//           branch from an instruction, stops the script naming the sc; so do paths whose
//           constants differ. An `sc` in any other PowerPC program stops the script. A call or
//           branch into the stub range on no function
//           record, and a call to a variable record, stops the script. An indirect call with no
//           flow is written per data or indirect reference it carries: a memory slot gives
//           "*0xSLOT"; a stack READ (a function pointer read from a parameter or local) gives
//           "*stack:<signed hex frame offset>" ("*stack:-0x68", "*stack:0x10"); a stack DATA
//           reference on a register operand ("call esp") or on a memory operand with an index
//           register ("callf [esp+ebx*4+disp]") gives "?"; any other stack reference, a slot that
//           is a sidecar variable record, and a reference into any other non-memory, non-external
//           space stop the script. A call with no flow and no such reference (call reg) gives "?".
//           A target in Ghidra's external
//           space (an imported function, e.g. "call dword ptr [IAT slot]") is written as
//           "ext:<library>!<name>" from the external location's library name and label
//           ("ext:KERNEL32.DLL!TlsGetValue"); an external target Ghidra cannot name stops the
//           script with the call's address. An import Ghidra labels by ordinal ("Ordinal_<n>",
//           SymbolUtilities.getOrdinalValue) is written with the name the ordinal table gives
//           for its library and ordinal ("ext:WS2_32.DLL!closesocket"); an ordinal import absent
//           from the table stops the script, naming the library and ordinal. A direct call to an
//           in-image thunk function whose thunk chain (Function.getThunkedFunction(true)) ends at
//           an external function in a named library (a "jmp [IAT slot]" stub) is written the
//           same way, as "ext:<library>!<name>" of that external function. A direct call to a
//           thunk whose chain ends at an in-image function, or at an external function in no
//           library (Ghidra's "<EXTERNAL>" library, e.g. a jump to an absolute address outside
//           the image, labelled "EXT_FUN_<addr>"), gives the thunk's "0xADDR".
//   drefs   data-reference targets ("0xADDR") from every instruction, in instruction order
//           (references whose type is data: read, write, data, pointer); a target that is a
//           sidecar variable record gives "ext:<library>!<name>"
//   strs    for each data reference whose target is a defined string, the string's raw bytes as
//           hex, in instruction order
//   imms    scalar operands in instruction order ("0x10", "-0x8"), including memory
//           displacements; a scalar equal to a reference target of the same operand is an
//           address and is not listed (it appears in callees/drefs)
//   mhash   SHA-1 (hex) of the body bytes in instruction order with every operand whose encoding
//           holds a layout-dependent address masked to zero via the instruction prototype's
//           operand value mask: relative branch/call targets; immediates, displacements and
//           target addresses whose value is an address in the program's memory; on PowerPC the
//           low half of a lis-built address (register + constant whose reference target minus the
//           constant has zero low 16 bits) and, in an ELF (PS3) program, r2/TOC-relative operands.
//           Registers-only operands, stack-frame offsets and other constants (field offsets) are
//           never masked, whatever references Ghidra attached to them
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.lang.InstructionPrototype;
import ghidra.program.model.lang.Mask;
import ghidra.program.model.lang.OperandType;
import ghidra.program.model.lang.Register;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Library;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.pcode.PcodeOp;
import ghidra.program.model.pcode.Varnode;
import ghidra.program.model.scalar.Scalar;
import ghidra.program.model.symbol.ExternalLocation;
import ghidra.program.model.symbol.RefType;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.Symbol;
import ghidra.program.model.symbol.SymbolUtilities;
import java.io.File;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class FnMnemonicSig extends GhidraScript {
    private static final String USAGE = "<outDir> <codeBlocks> <ordinalTable> <imports|->";
    private static final String IMPORTS_HEADER = "address\tkind\tlibrary\tordinal\tname";
    private static final String PRX_IMPORTS_HEADER = "address\tkind\tlibrary\tfnid\tname\tstub";
    // The last two words of an Xbox 360 import stub: mtctr r11; bctr.
    private static final int STUB_MTCTR = 0x7d6903a6;
    private static final int STUB_BCTR = 0x4e800420;
    private static final int STUB_SIZE = 16;
    // The PowerPC system call instruction with LEV 0.
    private static final int SC_WORD = 0x44000002;

    // Export name per "<library>\t<ordinal>", from the ordinal table (script argument 3).
    private final Map<String, String> ordinalNames = new HashMap<>();

    // Sidecar records by address (script argument 4): "ext:<library>!<name>" per function record
    // and per variable record.
    private final Map<Long, String> stubImports = new HashMap<>();
    private final Map<Long, String> varImports = new HashMap<>();
    private long stubLo = 0, stubHi = 0;
    // Whether the sidecar is a PRX (PS3) imports sidecar.
    private boolean prxImports = false;

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
            Address a = toAddr(addr);
            if (!currentProgram.getMemory().contains(a)) {
                throw new IllegalArgumentException("imports sidecar row " + where + ": " + f[0]
                    + " is not in " + currentProgram.getName() + "'s memory");
            }
            String text = "ext:" + f[2] + "!" + f[4];
            if (stubImports.containsKey(addr) || varImports.containsKey(addr)) {
                throw new IllegalArgumentException("imports sidecar row " + where + " repeats " + f[0]);
            }
            if (f[1].equals("function")) {
                int w2 = getInt(a.add(8)), w3 = getInt(a.add(12));
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
            Address a = toAddr(addr);
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
            byte[] got = getBytes(a, want.length);
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
        if (getFunctionAt(a) != null) {
            throw new IllegalStateException(site + "a path reaches the entry of " + getFunctionAt(a).getName(true)
                + " at " + a + " with no write of r11");
        }
        if (!f.getBody().contains(a)) {
            throw new IllegalStateException(site + "a path leaves the function body at " + a);
        }
        List<Instruction> out = new ArrayList<>();
        for (Reference r : getReferencesTo(a)) {
            Instruction from = getInstructionAt(r.getFromAddress());
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

    private boolean inStubRange(Address t) {
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

    // Script argument <index>; the script stops with the usage line when it is absent.
    private String requiredArg(int index) {
        String[] args = getScriptArgs();
        if (args.length <= index) {
            throw new IllegalArgumentException("missing script argument " + (index + 1)
                + "; usage: " + getClass().getSimpleName() + ".java " + USAGE);
        }
        return args[index];
    }

    private static String hex(byte[] b) {
        StringBuilder sb = new StringBuilder(b.length * 2);
        for (byte x : b) sb.append(String.format("%02x", x & 0xff));
        return sb.toString();
    }

    private static String addrHex(Address a) {
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
        String lib = el.getLibraryName();
        String label = el.getLabel();
        if (lib == null || lib.isEmpty() || Library.UNKNOWN.equals(lib)
                || label == null || label.isEmpty()) {
            throw new IllegalStateException("call '" + call + "' at " + call.getAddress()
                + " targets " + t + " whose import has library '" + lib
                + "' and label '" + label + "'");
        }
        int ordinal = SymbolUtilities.getOrdinalValue(label);
        if (ordinal < 0) return "ext:" + lib + "!" + label;
        String name = ordinalNames.get(lib + "\t" + ordinal);
        if (name == null) {
            throw new IllegalStateException("call '" + call + "' at " + call.getAddress()
                + " targets " + t + ", import " + lib + " ordinal " + ordinal + " ('" + label
                + "'), which the ordinal table " + requiredArg(2) + " does not name");
        }
        return "ext:" + lib + "!" + name;
    }

    private static String scalarHex(Scalar s) {
        long v = s.isSigned() ? s.getSignedValue() : s.getUnsignedValue();
        return v < 0 ? "-0x" + Long.toHexString(-v) : "0x" + Long.toHexString(v);
    }

    private static void jsonList(StringBuilder sb, String key, List<String> vals) {
        sb.append(",\"").append(key).append("\":[");
        for (int i = 0; i < vals.size(); i++) {
            if (i > 0) sb.append(',');
            sb.append('"').append(vals.get(i)).append('"');
        }
        sb.append(']');
    }

    // Operand i is masked in mhash when its encoding holds a layout-dependent address:
    //   - a relative branch/call target;
    //   - an immediate, displacement or target address whose value is an address in the program's
    //     memory (x86 `[0x00b05128]`, `[ESI*0x4 + 0xe79220]`, `push 0x00c1d2e0`, a PowerPC `bl`);
    //   - PowerPC, the constant read from the instruction word (signed low halfword): in addis/lis
    //     when, shifted left 16, it is an address in the program's memory (the high half of an
    //     address); in any other instruction when one of the instruction's non-stack memory
    //     references minus the constant has zero low 16 bits (the low half of a lis-built address);
    //   - PowerPC in an ELF program (PS3): an operand based on r2, the TOC pointer, whose offsets
    //     move with the TOC's contents.
    // Never masked: operands made only of registers, stack-frame offsets, and other constants
    // (field offsets such as `[EDX + 0x23c]`), whatever references Ghidra attached to them.
    private boolean isAddressOperand(Instruction ins, int i) throws Exception {
        Object[] objs = ins.getOpObjects(i);
        boolean registersOnly = objs.length > 0, r2 = false;
        for (Object o : objs) {
            if (o instanceof Register) {
                if (((Register) o).getName().equals("r2")) r2 = true;
            } else {
                registersOnly = false;
            }
        }
        if (registersOnly) return false;
        Reference[] refs = ins.getOperandReferences(i);
        for (Reference r : refs) if (r.isStackReference()) return false;
        if (OperandType.isRelative(ins.getOperandType(i))) return true;
        for (Object o : objs) {
            Long v = o instanceof Scalar ? Long.valueOf(((Scalar) o).getUnsignedValue())
                : o instanceof Address ? Long.valueOf(((Address) o).getOffset()) : null;
            if (v == null) continue;
            Address a = currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v, true);
            if (a != null && currentProgram.getMemory().contains(a)) return true;
        }
        if (!isPowerPC()) return false;
        boolean hasScalar = false;
        for (Object o : objs) hasScalar |= o instanceof Scalar;
        if (!hasScalar) return false;
        if (r2 && currentProgram.getExecutableFormat().contains("ELF")) return true;
        // The constant of a PowerPC D-form instruction is the signed low halfword of its word;
        // Ghidra may show it with the sign folded into the mnemonic (`subi r6,r11,0xbc4` for
        // addi -0xbc4), so it is read from the bytes.
        byte[] w = ins.getBytes();
        if (w.length != 4) {
            throw new IllegalStateException("PowerPC instruction '" + ins + "' at " + ins.getMinAddress()
                + " is " + w.length + " bytes, not 4");
        }
        int word = ((w[0] & 0xff) << 24) | ((w[1] & 0xff) << 16) | ((w[2] & 0xff) << 8) | (w[3] & 0xff);
        long c = (short) (word & 0xffff);
        // addis/lis (primary opcode 15): the constant is the high half of an address when, shifted
        // into place, it is an address in the program's memory.
        if ((word >>> 26) == 15) {
            Address hi = currentProgram.getAddressFactory().getDefaultAddressSpace()
                .getAddress((c << 16) & 0xffffffffL, true);
            if (hi != null && currentProgram.getMemory().contains(hi)) return true;
        }
        // The low half of a lis-built address: a memory reference of the instruction (on any
        // operand; Ghidra puts it on the destination register of an addi) minus the constant has
        // zero low 16 bits.
        for (Reference r : ins.getReferencesFrom()) {
            if (r.isStackReference() || !r.getToAddress().isMemoryAddress()) continue;
            if (((r.getToAddress().getOffset() - c) & 0xffffL) == 0) return true;
        }
        return false;
    }

    private boolean isPowerPC() {
        return currentProgram.getLanguage().getProcessor().toString().equals("PowerPC");
    }

    // Instruction bytes with the address operands zeroed. Stops the script when the prototype
    // gives no usable operand mask for an operand that must be masked.
    private byte[] maskedBytes(Instruction ins) throws Exception {
        byte[] b = ins.getBytes();
        InstructionPrototype proto = ins.getPrototype();
        for (int i = 0; i < ins.getNumOperands(); i++) {
            if (!isAddressOperand(ins, i)) continue;
            Mask m = proto.getOperandValueMask(i);
            if (m == null) {
                throw new IllegalStateException("no operand value mask for operand " + i + " of '"
                    + ins + "' at " + ins.getAddress());
            }
            byte[] mb = m.getBytes();
            if (mb.length > b.length) {
                throw new IllegalStateException("operand value mask (" + mb.length
                    + " bytes) is longer than the instruction (" + b.length + " bytes) for '"
                    + ins + "' at " + ins.getAddress());
            }
            for (int k = 0; k < mb.length; k++) b[k] = (byte) (b[k] & ~mb[k]);
        }
        return b;
    }

    @Override
    public void run() throws Exception {
        String outDir = requiredArg(0);
        List<MemoryBlock> code = new ArrayList<>();
        for (String name : requiredArg(1).split(",")) {
            MemoryBlock b = currentProgram.getMemory().getBlock(name);
            if (b == null) {
                throw new IllegalArgumentException("no memory block named '" + name + "' in " + currentProgram.getName());
            }
            if (!b.isExecute()) {
                throw new IllegalArgumentException("memory block '" + name + "' is not executable");
            }
            code.add(b);
        }
        loadOrdinalTable(requiredArg(2));
        String imports = requiredArg(3);
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
        String prog = currentProgram.getName().replaceAll("[^A-Za-z0-9._-]", "_");
        File out = new File(outDir, "fnsig_" + prog + ".json");
        PrintWriter pw = new PrintWriter(out, "UTF-8");
        pw.println("{");
        MessageDigest md = MessageDigest.getInstance("SHA-1");
        MessageDigest mbd = MessageDigest.getInstance("SHA-1");
        boolean first = true;
        int nfn = 0, stubFunctions = 0;
        boolean powerPc = currentProgram.getLanguage().getProcessor().toString().equals("PowerPC");
        if (prxImports) {
            r11 = currentProgram.getRegister("r11");
            if (r11 == null) {
                throw new IllegalStateException(currentProgram.getName() + " was given a PRX imports"
                    + " sidecar but its language has no register r11");
            }
            r11Lo = r11.getAddress().getOffset();
            r11Hi = r11Lo + r11.getMinimumByteSize();
        }
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            long a = f.getEntryPoint().getOffset();
            boolean inCode = false;
            for (MemoryBlock b : code) inCode |= b.contains(f.getEntryPoint());
            if (!inCode || f.isThunk()) continue;
            if (inStubRange(f.getEntryPoint())) {
                if (stubImports.containsKey(a)) {
                    stubFunctions++;
                    continue;
                }
                throw new IllegalStateException("function " + f.getName(true) + " at "
                    + f.getEntryPoint() + " starts inside the import stub range on no function record");
            }
            StringBuilder mn = new StringBuilder();
            int n = 0, calls = 0;
            List<String> callees = new ArrayList<>();
            List<String> drefs = new ArrayList<>();
            List<String> strs = new ArrayList<>();
            List<String> imms = new ArrayList<>();
            mbd.reset();
            // walk the function body in address order
            java.util.Iterator<Instruction> it = currentProgram.getListing().getInstructions(f.getBody(), true).iterator();
            while (it.hasNext()) {
                Instruction m = it.next();
                mn.append(m.getMnemonicString()).append(';');
                n++;
                if (m.getFlowType().isCall()) {
                    calls++;
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
                    calls++;
                    callees.add("sys:" + syscallNumber(m, f));
                }
                for (Reference r : m.getReferencesFrom()) {
                    RefType rt = r.getReferenceType();
                    if (!rt.isData() || !r.getToAddress().isMemoryAddress()) continue;
                    String var = varImports.get(r.getToAddress().getOffset());
                    drefs.add(var != null ? var : addrHex(r.getToAddress()));
                    Data d = getDataAt(r.getToAddress());
                    if (d != null && d.hasStringValue()) strs.add(hex(d.getBytes()));
                }
                for (int oi = 0; oi < m.getNumOperands(); oi++) {
                    Reference[] orefs = m.getOperandReferences(oi);
                    for (Object o : m.getOpObjects(oi)) {
                        if (!(o instanceof Scalar)) continue;
                        Scalar s = (Scalar) o;
                        boolean isRefTarget = false;
                        for (Reference r : orefs) {
                            if (r.getToAddress().getOffset() == s.getUnsignedValue()) isRefTarget = true;
                        }
                        if (!isRefTarget) imms.add(scalarHex(s));
                    }
                }
                mbd.update(maskedBytes(m));
            }
            md.reset();
            byte[] dig = md.digest(mn.toString().getBytes("UTF-8"));
            StringBuilder sig = new StringBuilder();
            for (int i = 0; i < 8; i++) sig.append(String.format("%02x", dig[i] & 0xff)); // 8-byte prefix
            StringBuilder row = new StringBuilder();
            row.append(String.format("\"0x%08x\":{\"sig\":\"%s\",\"n\":%d,\"sz\":%d,\"calls\":%d",
                a, sig.toString(), n, f.getBody().getNumAddresses(), calls));
            jsonList(row, "callees", callees);
            jsonList(row, "drefs", drefs);
            jsonList(row, "strs", strs);
            jsonList(row, "imms", imms);
            row.append(",\"mhash\":\"").append(hex(mbd.digest())).append("\"}");
            if (!first) pw.println(","); first = false;
            pw.print(row.toString());
            nfn++;
        }
        pw.println("\n}");
        pw.close();
        if (prxImports) {
            println("FnMnemonicSig PRX: " + stubFunctions + " import stub functions not written as keys; "
                + (scOnePath + scJoins) + " sc sites: " + scOnePath + " with r11 written on one path, "
                + scJoins + " through joins whose every path writes the same constant");
        }
        println("FnMnemonicSig: " + nfn + " functions in " + requiredArg(1) + " -> " + out.getAbsolutePath());
    }
}
