// Per-function content signature for cross-build (v1.0 vs v1.1) diffing. The 1.1 patch moved
// functions to new addresses, so a byte/address diff is meaningless. Instead signature each
// .text function by its instruction-MNEMONIC sequence (invariant to addresses/immediates) plus
// its size and instruction count. Same code moved => identical mnemonic-sig; a patched function
// => changed sig. Run once per program (-process <name>) and diff the two JSONs offline.
//
// Args: <outDir>  — writes <outDir>/fnsig_<programName>.json  => { "0xADDR": {...} } with fields:
//   sig     8-byte SHA-1 prefix (hex) of the mnemonic sequence "mov;push;call;..."
//   n       instruction count
//   sz      body size in bytes
//   calls   number of call instructions
//   callees call targets in instruction order (duplicates kept). A direct call gives its target
//           "0xADDR"; an indirect call through a referenced memory slot gives "*0xSLOT"; an
//           indirect call with no reference (call reg) gives "?".
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
    private static final String USAGE = "<outDir>";

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
        MemoryBlock text = currentProgram.getMemory().getBlock(".text");
        long lo = text.getStart().getOffset(), hi = text.getEnd().getOffset();
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
            if (a < lo || a > hi || f.isThunk()) continue;
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
                        for (Address t : flows) callees.add(addrHex(t));
                    } else {
                        boolean slot = false;
                        for (Reference r : m.getReferencesFrom()) {
                            if (r.getReferenceType().isData() || r.getReferenceType().isIndirect()) {
                                callees.add("*" + addrHex(r.getToAddress()));
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
        println("FnMnemonicSig: " + nfn + " .text functions -> " + out.getAbsolutePath());
    }
}
