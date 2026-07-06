// Memory-coverage report: per executable block, how many bytes are covered by defined
// functions vs. left undisassembled. Answers "how much code is missing from the decomp
// export and where" — distinguishes recoverable game code from SecuROM VM/obfuscation
// regions (whose flow targets are runtime-decrypted, so they never disassemble statically).
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSet;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.mem.MemoryBlock;

public class CoverageReport extends GhidraScript {
    @Override
    public void run() throws Exception {
        // 1) union of all function bodies
        AddressSet funcSet = new AddressSet();
        int nf = 0;
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            funcSet.add(f.getBody());
            nf++;
        }
        long funcBytes = funcSet.getNumAddresses();

        // 2) union of all disassembled instructions (a superset of function bodies:
        //    catches code Ghidra disassembled but never wrapped in a function)
        AddressSet insnSet = new AddressSet();
        long insnCount = 0;
        for (Instruction ins : currentProgram.getListing().getInstructions(true)) {
            insnSet.add(ins.getMinAddress(), ins.getMaxAddress());
            insnCount++;
        }

        println("=== MEMORY BLOCKS ===");
        long execTotal = 0, execFunc = 0, execInsn = 0;
        for (MemoryBlock b : currentProgram.getMemory().getBlocks()) {
            println(String.format("BLOCK %-14s %s-%s size=%d exec=%b init=%b read=%b write=%b",
                b.getName(), b.getStart(), b.getEnd(), b.getSize(),
                b.isExecute(), b.isInitialized(), b.isRead(), b.isWrite()));
        }

        println("\n=== EXECUTABLE-BLOCK COVERAGE ===");
        for (MemoryBlock b : currentProgram.getMemory().getBlocks()) {
            if (!b.isExecute()) continue;
            AddressSet blk = new AddressSet(b.getStart(), b.getEnd());
            long size = b.getSize();
            long fcov = blk.intersect(funcSet).getNumAddresses();
            long icov = blk.intersect(insnSet).getNumAddresses();
            println(String.format("EXEC %-14s %s-%s size=%d func=%d(%.1f%%) insn=%d(%.1f%%) undisasm=%d",
                b.getName(), b.getStart(), b.getEnd(), size,
                fcov, 100.0 * fcov / size, icov, 100.0 * icov / size, size - icov));
            execTotal += size; execFunc += fcov; execInsn += icov;
        }

        println(String.format(
            "\nTOTALS: functions=%d funcBytes=%d instructions=%d insnBytes=%d",
            nf, funcBytes, insnCount, insnSet.getNumAddresses()));
        println(String.format(
            "EXEC TOTAL=%d  func-covered=%d (%.1f%%)  insn-covered=%d (%.1f%%)  undisassembled=%d (%.1f%%)",
            execTotal, execFunc, 100.0 * execFunc / execTotal,
            execInsn, 100.0 * execInsn / execTotal,
            execTotal - execInsn, 100.0 * (execTotal - execInsn) / execTotal));
    }
}
