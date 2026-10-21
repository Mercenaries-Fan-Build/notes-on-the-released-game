// Raw-disassemble the byte stream around 0x00414B0B (the unresolvable prime-suspect call site) to
// identify the function it belongs to and see the alloc + the store that follows. No createFunction
// (that failed), just walk instructions, force-disassembling, and tag each with its owning function.
// Writes <outPath> (script argument 1).
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.mem.Memory;

import java.io.File;
import java.io.PrintWriter;

public class DumpAround414B0B extends GhidraScript {

    private static final long START = 0x00414A40L;
    private static final long END   = 0x00414BC0L;
    private static final String USAGE = "<outPath>";
    private String outPath;

    // Script argument <index>; the script stops with the usage line when it is absent.
    private String requiredArg(int index) {
        String[] args = getScriptArgs();
        if (args.length <= index) {
            throw new IllegalArgumentException("missing script argument " + (index + 1)
                + "; usage: " + getClass().getSimpleName() + ".java " + USAGE);
        }
        return args[index];
    }

    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }

    @Override
    public void run() throws Exception {
        outPath = requiredArg(0);
        Memory mem = currentProgram.getMemory();
        PrintWriter fp = new PrintWriter(new File(outPath), "UTF-8");
        try {
            fp.println("# raw disasm 0x" + Long.toHexString(START) + "..0x" + Long.toHexString(END));
            Address a = addr(START);
            Address end = addr(END);
            while (a.compareTo(end) < 0) {
                Instruction insn = getInstructionAt(a);
                if (insn == null) { try { disassemble(a); } catch (Exception e) {} insn = getInstructionAt(a); }
                if (insn == null) {
                    int b = mem.getByte(a) & 0xff;
                    fp.println(String.format("%08x  db %02X", a.getOffset(), b));
                    a = a.add(1);
                } else {
                    Function fn = getFunctionContaining(a);
                    String tag = (fn != null) ? fn.getName() + "+" + (a.getOffset() - fn.getEntryPoint().getOffset()) : "-";
                    fp.println(String.format("%08x  %-44s [%s]", a.getOffset(), insn.toString(), tag));
                    a = a.add(insn.getLength());
                }
            }
        } finally { fp.close(); }
        println("done");
    }
}
