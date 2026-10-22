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
//           The call list, the ordinal table and the imports sidecar are CallList.java's (shared
//           with ExportFunctions.java).
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
//           high half of an address in addis/lis, the low half of a lis-built address, and, in an
//           ELF (PS3) program, r2/TOC-relative operands (see isAddressOperand). Registers-only
//           operands, stack-frame offsets and other constants (field offsets) are not masked
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
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.scalar.Scalar;
import ghidra.program.model.symbol.RefType;
import ghidra.program.model.symbol.Reference;
import java.io.File;
import java.io.PrintWriter;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.List;

public class FnMnemonicSig extends GhidraScript {
    private static final String USAGE = "<outDir> <codeBlocks> <ordinalTable> <imports|->";

    // Script argument <index>; the script stops with the usage line when it is absent.
    private String requiredArg(int index) {
        String[] args = getScriptArgs();
        if (args.length <= index) {
            throw new IllegalArgumentException("missing script argument " + (index + 1)
                + "; usage: " + getClass().getSimpleName() + ".java " + USAGE);
        }
        return args[index];
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
    // Not masked: operands made only of registers, stack-frame offsets, and other constants
    // (field offsets such as `[EDX + 0x23c]`).
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
        // The constant is the signed low halfword of the instruction word.
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
        // The low half of a lis-built address: a non-stack memory reference from any operand of
        // the instruction, minus the constant, has zero low 16 bits.
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
        CallList callList = new CallList(this, requiredArg(2), requiredArg(3));
        String prog = currentProgram.getName().replaceAll("[^A-Za-z0-9._-]", "_");
        File out = new File(outDir, "fnsig_" + prog + ".json");
        PrintWriter pw = new PrintWriter(out, "UTF-8");
        pw.println("{");
        MessageDigest md = MessageDigest.getInstance("SHA-1");
        MessageDigest mbd = MessageDigest.getInstance("SHA-1");
        boolean first = true;
        int nfn = 0, stubFunctions = 0;
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            long a = f.getEntryPoint().getOffset();
            boolean inCode = false;
            for (MemoryBlock b : code) inCode |= b.contains(f.getEntryPoint());
            if (!inCode || f.isThunk()) continue;
            if (callList.inStubRange(f.getEntryPoint())) {
                if (callList.isStubRecord(a)) {
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
                calls += callList.addCallees(m, f, callees);
                for (Reference r : m.getReferencesFrom()) {
                    RefType rt = r.getReferenceType();
                    if (!rt.isData() || !r.getToAddress().isMemoryAddress()) continue;
                    String var = callList.varImport(r.getToAddress().getOffset());
                    drefs.add(var != null ? var : CallList.addrHex(r.getToAddress()));
                    Data d = getDataAt(r.getToAddress());
                    if (d != null && d.hasStringValue()) strs.add(CallList.hex(d.getBytes()));
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
            row.append(",\"mhash\":\"").append(CallList.hex(mbd.digest())).append("\"}");
            if (!first) pw.println(","); first = false;
            pw.print(row.toString());
            nfn++;
        }
        pw.println("\n}");
        pw.close();
        if (callList.isPrx()) {
            println("FnMnemonicSig PRX: " + stubFunctions + " import stub functions not written as keys; "
                + (callList.scOnePath() + callList.scJoins()) + " sc sites: " + callList.scOnePath() + " with r11 written on one path, "
                + callList.scJoins() + " through joins whose every path writes the same constant");
        }
        println("FnMnemonicSig: " + nfn + " functions in " + requiredArg(1) + " -> " + out.getAbsolutePath());
    }
}
