import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Instruction;

public class DisasmTest extends GhidraScript {
    public void run() throws Exception {
        Address a = toAddr(0x82170000L);
        clearListing(a, a.add(256));
        disassemble(a);
        Instruction ins = getInstructionAt(a);
        if (ins == null) { println("STILL NULL at " + a); return; }
        for (int i = 0; i < 20 && ins != null; i++) {
            println(ins.getAddress() + ": " + ins.toString());
            ins = getInstructionAfter(ins);
        }
    }
}
