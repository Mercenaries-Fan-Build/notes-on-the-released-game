// poolguard caught a texture-record (0xF011157A, 12-byte {name_hash,type,0}) buffer OVERFLOW
// written by FUN_004cf340 at 0x004CF5AD / 0x004CF43B / 0x004CF42C. The buffer is sized for fewer
// records than the DLC chunk contains -> overruns adjacent pool blocks (free-list links + canary).
// Decompile the writer + the alloc site + the consumers up the stack to find the buffer allocation
// and the record COUNT it is sized from (vs the count the write loop uses).
//   writer stack: 0x004CF5AD,0x004CF43B,0x004CF42C (FUN_004cf340) <- 0x005FD598 <- 0x0046FE50
//                 <- 0x004C0B6F/0x004C1672/0x004C1540 <- 0x00630FB1 <- 0x00631A90/0x0063193D
//   alloc callers seen: 0x0085BEA8 (16B P), 0x0085BFB0 (4908B via D760)
// Writes output/_ghidra/texbuf_overflow.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.util.LinkedHashSet;
import java.util.Set;

public class TexRecordBufferOverflow extends GhidraScript {
    private static final long[] TARGETS = {
        0x004CF340L,  // the writer (CHDR/chunk reader)
        0x0085BEA8L,  // alloc caller (16B P)
        0x0085BFB0L,  // alloc caller (4908B big buffer via D760)
        0x005FD598L,  // up-stack consumer
        0x0046FE50L,
        0x004C0B6FL,
        0x00630FB1L,  // texture-list consumer
        0x00631A90L,
    };
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\texbuf_overflow.txt";
    private PrintWriter fp;
    private DecompInterface decomp;
    private ConsoleTaskMonitor mon;
    private final Set<Long> done = new LinkedHashSet<>();
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }
    private void decompileVa(long va) {
        Function f = getFunctionContaining(addr(va));
        if (f == null) { try { disassemble(addr(va)); f = createFunction(addr(va), null); } catch (Exception e) {} }
        if (f == null) { w("  (no fn @0x" + Long.toHexString(va) + ")"); return; }
        long key = f.getEntryPoint().getOffset();
        if (!done.add(key)) { w("  (dup " + f.getName() + ")"); return; }
        try {
            DecompileResults res = decomp.decompileFunction(f, 120, mon);
            w("============================================================");
            w(">>> " + f.getName() + " @" + f.getEntryPoint() + "  (for va 0x" + Long.toHexString(va) + ")");
            if (res != null && res.decompileCompleted()) w(res.getDecompiledFunction().getC());
            else w("  DECOMP FAIL");
        } catch (Exception e) { w("  EXC " + e); }
    }
    @Override
    public void run() throws Exception {
        new File(OUT).getParentFile().mkdirs();
        fp = new PrintWriter(new File(OUT), "UTF-8");
        decomp = new DecompInterface(); decomp.openProgram(currentProgram);
        mon = new ConsoleTaskMonitor();
        try {
            for (long t : TARGETS) decompileVa(t);
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
