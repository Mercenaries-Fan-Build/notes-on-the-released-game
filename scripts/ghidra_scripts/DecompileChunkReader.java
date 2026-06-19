// Decompile the chunk-stream reader internals behind FUN_0067a7fa's {int,hash,hash} array:
//   - FUN_00464780  GetChunkDataReader (sets up the reader object the parser reads count3 from)
//   - FUN_00825dc0  string reader (returns the SAME string each record -> identical FNV hashes)
//   - FUN_0067a7fa  re-decompile (count3 source + descriptor-table navigation)
// Goal: find why count3 overruns the real record data. Writes output/_ghidra/chunkreader_decomp.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.mem.Memory;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;

public class DecompileChunkReader extends GhidraScript {

    private static final long[] TARGETS = { 0x00464780L, 0x00825DC0L, 0x0067A7FAL };
    private static final String[] LABELS = {
        "FUN_00464780 GetChunkDataReader (reader setup)",
        "FUN_00825DC0 string reader (repeating strings)",
        "FUN_0067A7FA chunk parser (count3 source + nav)",
    };
    private static final String OUT_DIR =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra";

    private PrintWriter fp;
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }

    private Function ensureFn(long va) throws Exception {
        FunctionManager fm = currentProgram.getFunctionManager();
        Function f = fm.getFunctionContaining(addr(va));
        if (f != null) return f;
        Memory mem = currentProgram.getMemory();
        long e = -1;
        for (long a = va; a > va - 0x4000; a--) {
            try {
                if ((mem.getByte(addr(a)) & 0xff) == 0x55 &&
                    (mem.getByte(addr(a + 1)) & 0xff) == 0x8b &&
                    (mem.getByte(addr(a + 2)) & 0xff) == 0xec) { e = a; break; }
            } catch (Exception ex) { }
        }
        if (e < 0) return null;
        disassemble(addr(e));
        f = createFunction(addr(e), null);
        if (f == null) f = fm.getFunctionContaining(addr(va));
        return f;
    }

    @Override
    public void run() throws Exception {
        new File(OUT_DIR).mkdirs();
        File out = new File(OUT_DIR, "chunkreader_decomp.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
            String bar = new String(new char[78]).replace("\0", "=");
            w("# Mercs2 chunk reader internals (count3 overrun investigation)");
            w("# program: " + currentProgram.getName());
            w("");
            for (int i = 0; i < TARGETS.length; i++) {
                w(bar);
                w(String.format("TARGET 0x%08x  %s", TARGETS[i], LABELS[i]));
                Function f = ensureFn(TARGETS[i]);
                if (f == null) { w("  (could not define function)"); w(""); continue; }
                w("  " + f.getName() + " entry=" + f.getEntryPoint()
                    + " size=" + f.getBody().getNumAddresses());
                try {
                    DecompileResults res = decomp.decompileFunction(f, 120, mon);
                    if (res != null && res.decompileCompleted()) w(res.getDecompiledFunction().getC());
                    else w("  DECOMP FAILED");
                } catch (Exception ex) { w("  DECOMP EXC: " + ex); }
                w("");
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
