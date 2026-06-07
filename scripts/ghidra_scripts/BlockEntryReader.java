// Confirm the block entry-table layout the ENGINE uses: 4-byte count + N*16-byte rows
// {name_hash, type_hash, field3, chunk_size}. We need to know if field3 (offset +8 in row) is a
// DATA-AREA OFFSET the engine uses to locate each entry's container, or a cookie.
// Approach: the engine reads entries with a 16-byte stride. Find functions that index a table with
// *(base + count*16) and read +8. We scan for the recurring access pattern by decompiling the
// block-open / entry-locate functions. Seed: FUN_00464780 (chunk reader open, used by 0x4cf340),
// FUN_004cf340 itself, and the world/grid load FUN_004cc030 region. Also dump raw bytes of a known
// DLC physics block entry table if present on disk for ground-truth (skipped here; binary only).
//
// We enumerate all functions that contain an instruction "<reg>*0x10" combined with a "+8" read,
// near a type-hash compare, and decompile the few unique ones.
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

public class BlockEntryReader extends GhidraScript {
    private static final long[] DIRECT = {
        0x00464780L, // chunk reader open
        0x004cc030L, // grid pool pop region
        0x004cbc90L, // guidmap getter caller chain
        0x00873140L, // FUN_00873140 (component registry insert seen in 0x46b590)
        0x00875fd0L, // per-node type dispatcher
        0x008731f0L  // chain to grid pop (from memory note)
    };
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\block_entry_reader.txt";
    private PrintWriter fp;
    private DecompInterface decomp;
    private ConsoleTaskMonitor mon;
    private final Set<Long> done = new LinkedHashSet<>();
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }
    private void decompileVa(long va, String tag) {
        Function f = getFunctionContaining(addr(va));
        if (f == null) { try { disassemble(addr(va)); f = createFunction(addr(va), null); } catch (Exception e) {} }
        if (f == null) { w("  (no fn @0x" + Long.toHexString(va) + ") " + tag); return; }
        long key = f.getEntryPoint().getOffset();
        if (!done.add(key)) { w("  (dup " + f.getName() + ") " + tag); return; }
        try {
            DecompileResults res = decomp.decompileFunction(f, 120, mon);
            w("  >>> " + f.getName() + " @" + f.getEntryPoint() + "  " + tag);
            if (res != null && res.decompileCompleted()) w(res.getDecompiledFunction().getC());
            else w("    DECOMP FAIL");
        } catch (Exception e) { w("    EXC " + e); }
    }
    @Override
    public void run() throws Exception {
        new File(OUT).getParentFile().mkdirs();
        fp = new PrintWriter(new File(OUT), "UTF-8");
        decomp = new DecompInterface(); decomp.openProgram(currentProgram);
        mon = new ConsoleTaskMonitor();
        try {
            for (long t : DIRECT) decompileVa(t, "direct");
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
