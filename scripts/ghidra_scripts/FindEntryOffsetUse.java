// Determine whether the engine uses the block entry-table 3rd u32 (row+8) as an ABSOLUTE byte
// offset to locate each entry's container, or walks containers sequentially by chunk_size (row+12).
// The block entry table: [u32 count][N * {u32 name_hash, u32 type_hash, u32 field3, u32 chunk_size}].
// We look for the loader that opens a block: reads count at [base], then iterates 16-byte rows.
// Heuristic scan: find instructions using stride 0x10 (16) as an array index multiplier within a
// function that also reads a u32 count first, and decompile unique candidates. Also seed the
// known WAD/block mount path. We brute-force by scanning every function for the access
// "*(X + i*0x10 + 8)" via the decompiler C text containing "* 0x10" AND "+ 8)" patterns is too
// noisy, so instead: enumerate callers of FUN_00464780 (descriptor reader) up the chain to the
// block opener, and decompile them.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.Reference;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.LinkedHashSet;
import java.util.Set;

public class FindEntryOffsetUse extends GhidraScript {
    private static final long SEED = 0x00464780L; // descriptor reader
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\entry_offset_use.txt";
    private PrintWriter fp;
    private DecompInterface decomp;
    private ConsoleTaskMonitor mon;
    private final Set<Long> done = new LinkedHashSet<>();
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }
    private String decompC(Function f) {
        try {
            DecompileResults res = decomp.decompileFunction(f, 120, mon);
            if (res != null && res.decompileCompleted()) return res.getDecompiledFunction().getC();
        } catch (Exception e) {}
        return null;
    }
    @Override
    public void run() throws Exception {
        new File(OUT).getParentFile().mkdirs();
        fp = new PrintWriter(new File(OUT), "UTF-8");
        decomp = new DecompInterface(); decomp.openProgram(currentProgram);
        mon = new ConsoleTaskMonitor();
        try {
            // BFS up the call graph from SEED to depth 3, decompiling each function and
            // flagging those whose C text contains a 16-byte (0x10) strided table read AND a
            // u32 count read — i.e. the block entry-table walker.
            Deque<long[]> q = new ArrayDeque<>(); // {va, depth}
            q.add(new long[]{SEED, 0});
            while (!q.isEmpty()) {
                long[] cur = q.poll();
                long va = cur[0]; int depth = (int) cur[1];
                Function f = getFunctionContaining(addr(va));
                if (f == null) continue;
                long key = f.getEntryPoint().getOffset();
                if (!done.add(key)) continue;
                String c = decompC(f);
                boolean stride16 = c != null && (c.contains("* 0x10") || c.contains("<< 4"));
                boolean entryish = c != null && c.contains("+ 8") && (c.contains("0x140e8728")
                    || c.contains("* 0x10"));
                w("============================================================");
                w(String.format(">>> %s @%s depth=%d  stride16=%b", f.getName(), f.getEntryPoint(), depth, stride16));
                if (c != null) w(c); else w("  DECOMP FAIL");
                if (depth < 3) {
                    for (Reference r : getReferencesTo(f.getEntryPoint())) {
                        if (!r.getReferenceType().isCall()) continue;
                        Function caller = getFunctionContaining(r.getFromAddress());
                        if (caller != null) q.add(new long[]{caller.getEntryPoint().getOffset(), depth + 1});
                    }
                }
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
