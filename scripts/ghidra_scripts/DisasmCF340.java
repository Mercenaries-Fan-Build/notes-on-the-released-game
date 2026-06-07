// Precise instruction disasm of FUN_004cf340 (the canary-confirmed texture-record writer:
// the MESH_B CHDR/CEXE/NODE/STAT behaviour-tree parser). Map the alloc sites the timeline named
// (0x4CF4E7, 0x4CF5AD, 0x4CF6A6, 0x4CF6C2) and the writer return-addresses (0x4CF43B) to the exact
// count-vs-alloc-vs-write, so we know which count drives the overrun. Tags each insn with its
// owning function. Writes output/_ghidra/cf340_disasm.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.mem.Memory;

import java.io.File;
import java.io.PrintWriter;

public class DisasmCF340 extends GhidraScript {

    private static final long START = 0x004CF340L;
    private static final long END   = 0x004CF700L;
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\cf340_disasm.txt";

    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }

    @Override
    public void run() throws Exception {
        Memory mem = currentProgram.getMemory();
        // make sure the function is defined so register/operand names resolve
        try { disassemble(addr(START)); createFunction(addr(START), null); } catch (Exception e) {}
        PrintWriter fp = new PrintWriter(new File(OUT), "UTF-8");
        try {
            fp.println("# FUN_004cf340 disasm 0x" + Long.toHexString(START) + "..0x" + Long.toHexString(END));
            fp.println("# alloc-site return addrs from timeline: 0x4CF4E7 0x4CF5AD 0x4CF6A6 0x4CF6C2 ; writer 0x4CF43B");
            Address a = addr(START), end = addr(END);
            while (a.compareTo(end) < 0) {
                Instruction insn = getInstructionAt(a);
                if (insn == null) { try { disassemble(a); } catch (Exception e) {} insn = getInstructionAt(a); }
                if (insn == null) {
                    fp.println(String.format("%08x  db %02X", a.getOffset(), mem.getByte(a) & 0xff));
                    a = a.add(1);
                } else {
                    long off = a.getOffset();
                    String mark = (off==0x4CF4E7L||off==0x4CF5ADL||off==0x4CF6A6L||off==0x4CF6C2L) ? "  <== ALLOC-SITE ret"
                                : (off==0x4CF43BL) ? "  <== writer ret" : "";
                    fp.println(String.format("%08x  %-46s%s", off, insn.toString(), mark));
                    a = a.add(insn.getLength());
                }
            }
        } finally { fp.close(); }
        println("done");
    }
}
