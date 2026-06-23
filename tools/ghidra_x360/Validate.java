// Ghidra Java script: validate the recovered Xbox PPC PE loads + disassembles.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.listing.Instruction;
import ghidra.app.cmd.disassemble.DisassembleCommand;

public class Validate extends GhidraScript {
    public void run() throws Exception {
        println("== VALIDATE ==");
        println("LANG: " + currentProgram.getLanguageID());
        println("IMAGEBASE: " + currentProgram.getImageBase());
        for (MemoryBlock b : currentProgram.getMemory().getBlocks()) {
            println("BLOCK " + b.getName() + " " + b.getStart() + " - " + b.getEnd()
                    + " (" + b.getSize() + ") x=" + b.isExecute());
        }
        Address addr = currentProgram.getAddressFactory().getAddress("0x82170000");
        new DisassembleCommand(addr, null, true).applyTo(currentProgram);
        println("DISASM @0x82170000 (first .pdata function):");
        Address a = addr;
        for (int i = 0; i < 16; i++) {
            Instruction ins = currentProgram.getListing().getInstructionAt(a);
            if (ins == null) { println("  " + a + ": (no instruction)"); break; }
            println("  " + a + ": " + ins.toString());
            a = ins.getMaxAddress().add(1);
        }
        println("== END VALIDATE ==");
    }
}
