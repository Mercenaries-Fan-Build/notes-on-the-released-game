// Per-function content signature for cross-build and cross-platform diffing. Builds place the
// same functions at different addresses, so a byte/address diff is meaningless. Instead signature
// each function in the named code blocks by its instruction-MNEMONIC sequence (invariant to
// addresses/immediates) plus its size and instruction count. Same code moved => identical
// mnemonic-sig; a patched function => changed sig. Run once per program (-process <name>) and diff
// the JSONs offline.
//
// Args: <outDir> <codeBlocks> <ordinalTable>  — <codeBlocks> is a comma-separated list of
//   executable memory block names (".text" for the PC images, ".text,BINK" for the Xbox 360
//   images); a name that is missing or not executable stops the script. <ordinalTable> is a
//   tab-separated file (pe_import_ordinals.tsv next to this script) of rows
//   "<library>\t<ordinal>\t<name>\t<source dll sha256>", '#' lines being comments; a malformed or
//   duplicate row stops the script. Writes <outDir>/fnsig_<programName>.json
//   => { "0xADDR": {...} } with fields:
//   sig     8-byte SHA-1 prefix (hex) of the mnemonic sequence "mov;push;call;..."
//   n       instruction count
//   sz      body size in bytes
//   calls   number of call instructions
//   callees call targets in instruction order (duplicates kept). A direct call gives its target
//           "0xADDR"; an indirect call through a referenced memory slot gives "*0xSLOT"; an
//           indirect call with no reference (call reg) gives "?". A target in Ghidra's external
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
//           (references whose type is data: read, write, data, pointer)
//   strs    for each data reference whose target is a defined string, the string's raw bytes as
//           hex, in instruction order
//   imms    scalar operands in instruction order ("0x10", "-0x8"), including memory
//           displacements; a scalar equal to a reference target of the same operand is an
//           address and is not listed (it appears in callees/drefs)
//   mhash   SHA-1 (hex) of the body bytes in instruction order with every operand that carries
//           a reference or is an address/relative operand (rel32/rel8 branch and call targets,
//           absolute memory addresses) masked to zero via the instruction prototype's operand
//           value mask
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.lang.InstructionPrototype;
import ghidra.program.model.lang.Mask;
import ghidra.program.model.lang.OperandType;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Library;
import ghidra.program.model.mem.MemoryBlock;
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
    private static final String USAGE = "<outDir> <codeBlocks> <ordinalTable>";

    // Export name per "<library>\t<ordinal>", from the ordinal table (script argument 3).
    private final Map<String, String> ordinalNames = new HashMap<>();

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

    // Callee text for a direct call flow target: a thunk function at t whose thunk chain ends at
    // an external function in a named library gives "ext:<library>!<name>" of that external
    // function; a thunk whose chain ends at an in-image function, or at an external function in
    // Ghidra's unknown library ("<EXTERNAL>"), gives the thunk's "0xADDR"; any other target gives
    // calleeText(call, t). Stops the script, naming the call and thunk, when the thunk has no
    // thunked function or the external function at the end of the chain has no external location.
    private String flowCalleeText(Instruction call, Address t) {
        if (!t.isMemoryAddress()) return calleeText(call, t);
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

    // Operand i is masked in mhash when it carries a reference or is an address / relative operand.
    private static boolean isAddressOperand(Instruction ins, int i) {
        if (ins.getOperandReferences(i).length > 0) return true;
        int t = ins.getOperandType(i);
        return OperandType.isAddress(t) || OperandType.isRelative(t)
            || OperandType.isCodeReference(t) || OperandType.isDataReference(t);
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
        String prog = currentProgram.getName().replaceAll("[^A-Za-z0-9._-]", "_");
        File out = new File(outDir, "fnsig_" + prog + ".json");
        PrintWriter pw = new PrintWriter(out, "UTF-8");
        pw.println("{");
        MessageDigest md = MessageDigest.getInstance("SHA-1");
        MessageDigest mbd = MessageDigest.getInstance("SHA-1");
        boolean first = true;
        int nfn = 0;
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            long a = f.getEntryPoint().getOffset();
            boolean inCode = false;
            for (MemoryBlock b : code) inCode |= b.contains(f.getEntryPoint());
            if (!inCode || f.isThunk()) continue;
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
                                callees.add("*" + calleeText(m, r.getToAddress()));
                                slot = true;
                            }
                        }
                        if (!slot) callees.add("?");
                    }
                }
                for (Reference r : m.getReferencesFrom()) {
                    RefType rt = r.getReferenceType();
                    if (!rt.isData() || !r.getToAddress().isMemoryAddress()) continue;
                    drefs.add(addrHex(r.getToAddress()));
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
        println("FnMnemonicSig: " + nfn + " functions in " + requiredArg(1) + " -> " + out.getAbsolutePath());
    }
}
