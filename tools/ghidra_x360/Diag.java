import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;

public class Diag extends GhidraScript {
    public void run() throws Exception {
        Address a = toAddr(0x82170000L);
        byte[] b = new byte[16];
        currentProgram.getMemory().getBytes(a, b);
        StringBuilder sb = new StringBuilder();
        for (byte x : b) sb.append(String.format("%02x ", x & 0xff));
        println("BYTES @" + a + ": " + sb);
        boolean ok = disassemble(a);
        println("disassemble() returned: " + ok);
        println("instr at a: " + getInstructionAt(a));
        // context register names (to see if VLE/mode context exists)
        var ctx = currentProgram.getProgramContext();
        for (var r : ctx.getContextRegisters()) {
            println("CTXREG: " + r.getName() + " = " + ctx.getValue(r, a, false));
        }
    }
}
