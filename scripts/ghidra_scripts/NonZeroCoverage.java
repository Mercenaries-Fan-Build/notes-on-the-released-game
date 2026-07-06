// Non-zero code coverage: per executable block, of the bytes that are actually non-zero
// (i.e. excluding zero-fill / padding), how many are covered by disassembled instructions.
// This is the meaningful "how much real content did we recover" metric — the raw block %%
// is diluted by the ~18.5 MB of .securom zero-fill.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSet;
import ghidra.program.model.address.AddressRange;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.mem.MemoryBlock;

public class NonZeroCoverage extends GhidraScript {
    @Override
    public void run() throws Exception {
        // union of all disassembled instruction bytes
        AddressSet insnSet = new AddressSet();
        for (Instruction ins : currentProgram.getListing().getInstructions(true))
            insnSet.add(ins.getMinAddress(), ins.getMaxAddress());

        long gNZ = 0, gNZcov = 0;
        println(String.format("%-12s %12s %12s %12s %8s", "block", "nonzero", "nz-covered", "nz-undisasm", "recov%"));
        for (MemoryBlock b : currentProgram.getMemory().getBlocks()) {
            if (!b.isExecute()) continue;
            long size = b.getSize();
            byte[] buf = new byte[(int) Math.min(size, 1 << 20)];

            // 1) mark which offsets are inside an instruction
            boolean[] isInsn = new boolean[(int) size];
            long base = b.getStart().getOffset();
            AddressSet blk = new AddressSet(b.getStart(), b.getEnd());
            for (AddressRange r : blk.intersect(insnSet).getAddressRanges()) {
                int lo = (int) (r.getMinAddress().getOffset() - base);
                int hi = (int) (r.getMaxAddress().getOffset() - base);
                for (int i = lo; i <= hi && i < size; i++) isInsn[i] = true;
            }

            // 2) walk bytes in 1MB chunks: count non-zero + non-zero-in-instruction
            long nz = 0, nzCov = 0;
            long off = 0;
            while (off < size) {
                int n = (int) Math.min(buf.length, size - off);
                int got;
                try { got = currentProgram.getMemory().getBytes(b.getStart().add(off), buf, 0, n); }
                catch (Exception e) { break; }
                for (int i = 0; i < got; i++) {
                    if (buf[i] != 0) {
                        nz++;
                        if (isInsn[(int) (off + i)]) nzCov++;
                    }
                }
                off += got;
                if (got == 0) break;
            }
            double pct = nz == 0 ? 100.0 : 100.0 * nzCov / nz;
            println(String.format("%-12s %12d %12d %12d %7.1f%%", b.getName(), nz, nzCov, nz - nzCov, pct));
            gNZ += nz; gNZcov += nzCov;
        }
        println(String.format("%-12s %12d %12d %12d %7.1f%%", "TOTAL(exec)", gNZ, gNZcov, gNZ - gNZcov,
            gNZ == 0 ? 100.0 : 100.0 * gNZcov / gNZ));
    }
}
