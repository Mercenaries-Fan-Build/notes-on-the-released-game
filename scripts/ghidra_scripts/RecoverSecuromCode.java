// Recover the SecuROM-relocated code that Ghidra's default analysis never reached.
// Stext/Sitext hold ~6 MB of dense, real x86 (decrypted in the live dump) that is entered
// only through SecuROM's runtime-computed jumps — so there are no static references for the
// analyzer to follow, and it stays as undefined bytes (never disassembled → never exported).
// This forces linear disassembly over the code-dense executable SecuROM blocks (skipping
// zero-fill), creates functions at run starts, then runs auto-analysis to propagate + clean
// up. Persists to the project (run WITHOUT -readOnly), so a subsequent decomp export sees it.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.mem.MemoryBlock;

public class RecoverSecuromCode extends GhidraScript {
    // Blocks to linear-disassemble. Stext/Sitext are dense code (recovered on the first pass;
    // re-listing them just steps past existing instructions). Sdata/.securom hold SecuROM's own
    // VM code (already plaintext in the dump) interleaved with encrypted data blobs + zero-fill —
    // force-disassembly recovers the VM-code portions; the encrypted blobs won't decode (they
    // decrypt only at runtime) and are reported as the still-missing remainder.
    private static final String[] CODE_BLOCKS = {"Stext", "Sitext", "Sdata", ".securom"};

    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }

    @Override
    public void run() throws Exception {
        // 1) clear the false-noreturn x87 math helpers (persist this fix)
        for (long a : new long[]{0x401740L, 0x401750L, 0x4017a0L, 0x401630L}) {
            Function f = getFunctionAt(addr(a));
            if (f != null && f.hasNoReturn()) { f.setNoReturn(false); println("cleared noreturn " + f.getName()); }
        }

        // 2) force linear disassembly over the code-dense SecuROM blocks
        for (String bn : CODE_BLOCKS) {
            MemoryBlock b = currentProgram.getMemory().getBlock(bn);
            if (b == null || !b.isExecute()) { println("skip " + bn); continue; }
            Address cur = b.getStart(), end = b.getEnd();
            long disasm = 0, runs = 0, zeros = 0;
            byte[] buf = new byte[4096];
            boolean prevGap = true;
            while (cur != null && cur.compareTo(end) <= 0) {
                Instruction ins = getInstructionAt(cur);
                if (ins != null) {                       // already code — step past it
                    cur = ins.getMaxAddress().add(1);
                    prevGap = false;
                    continue;
                }
                int by;
                try { by = currentProgram.getMemory().getByte(cur) & 0xff; }
                catch (Exception e) { break; }
                if (by == 0x00) {                        // fast-skip zero-fill runs
                    long skip = 1;
                    try {
                        int n = currentProgram.getMemory().getBytes(cur, buf);
                        int i = 0; while (i < n && buf[i] == 0) i++;
                        skip = Math.max(1, i);
                    } catch (Exception e) { /* keep 1 */ }
                    zeros += skip; cur = cur.add(skip); prevGap = true;
                    continue;
                }
                try { disassemble(cur); } catch (Exception e) { /* fallthrough */ }
                ins = getInstructionAt(cur);
                if (ins != null) {
                    disasm++;
                    if (prevGap && getFunctionContaining(cur) == null) {   // new run → make a fn
                        try { if (createFunction(cur, null) != null) runs++; } catch (Exception e) {}
                    }
                    cur = ins.getMaxAddress().add(1);
                    prevGap = false;
                } else {
                    cur = cur.add(1); prevGap = true;     // undecodable byte
                }
                if (monitor.isCancelled()) break;
            }
            println(String.format("%s: instructions=%d newFns=%d zeroBytesSkipped=%d", bn, disasm, runs, zeros));
        }

        // 3) report per-block non-zero coverage (contained; no analyzeAll propagation so a
        //    mis-disassembled data byte can't cascade into wide garbage).
        ghidra.program.model.address.AddressSet insnSet = new ghidra.program.model.address.AddressSet();
        for (Instruction ins : currentProgram.getListing().getInstructions(true))
            insnSet.add(ins.getMinAddress(), ins.getMaxAddress());
        println(String.format("%-12s %12s %12s %8s", "block", "nonzero", "nz-covered", "recov%"));
        for (MemoryBlock b : currentProgram.getMemory().getBlocks()) {
            if (!b.isExecute()) continue;
            long size = b.getSize(), base = b.getStart().getOffset();
            boolean[] isInsn = new boolean[(int) size];
            ghidra.program.model.address.AddressSet blk =
                new ghidra.program.model.address.AddressSet(b.getStart(), b.getEnd());
            for (ghidra.program.model.address.AddressRange r : blk.intersect(insnSet).getAddressRanges()) {
                int lo = (int) (r.getMinAddress().getOffset() - base);
                int hi = (int) (r.getMaxAddress().getOffset() - base);
                for (int i = lo; i <= hi && i < size; i++) isInsn[i] = true;
            }
            byte[] buf = new byte[(int) Math.min(size, 1 << 20)];
            long nz = 0, nzCov = 0, off = 0;
            while (off < size) {
                int n = (int) Math.min(buf.length, size - off), got;
                try { got = currentProgram.getMemory().getBytes(b.getStart().add(off), buf, 0, n); }
                catch (Exception e) { break; }
                if (got == 0) break;
                for (int i = 0; i < got; i++) if (buf[i] != 0) { nz++; if (isInsn[(int) (off + i)]) nzCov++; }
                off += got;
            }
            println(String.format("%-12s %12d %12d %7.1f%%", b.getName(), nz, nzCov,
                nz == 0 ? 100.0 : 100.0 * nzCov / nz));
        }
        println("done.");
    }
}
