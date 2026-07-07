// Export decompiled C for functions, for static review of the world-load texture-table
// overflow. Two modes controlled by CLUSTER_ONLY:
//   * CLUSTER_ONLY=true  -> only the texture-loader call-graph (the functions containing the
//     poolguard overflow call-sites + producer/consumer chain). Fast, the high-value subset.
//   * CLUSTER_ONLY=false -> every FUN_* in .text (the user's "export all"). Large + slow.
// Each function is emitted once (dedup by entry), sorted by address, with a header line
//   ==== FUN_xxxx @addr  size=N  callers=[...] ====
// Writes output/_ghidra/<all_functions|texloader_cluster>_decomp.txt
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Reference;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.TreeMap;

public class DecompileAllFunctions extends GhidraScript {
    // Flip to false to dump every FUN_* in .text.
    private static final boolean CLUSTER_ONLY = false;

    // Seed addresses: the overflow call-sites poolguard named + the producer/consumer chain.
    // The containing function of each is decompiled (deduped).
    private static final long[] SEEDS = {
        0x00470F00L, 0x00470F35L, 0x00470FD8L, 0x00470FFCL, 0x0047133EL, // pre/around builder
        0x00470F90L,                                                     // FUN_00470f90
        0x00471406L, 0x00471497L, 0x00471536L, 0x004715CBL, 0x0047166EL,
        0x00471707L, 0x0047189AL,
        0x00471AFDL,                                                     // *** overflower caller ***
        0x00471B20L, 0x00471B4AL,                                        // FUN_00471b20
        0x00414B0BL,                                                     // another 16B packer caller
        0x004811C0L,                                                     // FUN_004811c0 producer (count)
        0x004CF340L,                                                     // CHDR/NODE/CEXE machine
        0x0046B590L, 0x0046C360L, 0x00466850L,                           // sibling 0xF011157A writers
        0x0085BEA8L, 0x0085BFB0L,                                        // alloc wrappers (16B / D760)
    };

    private static final String OUT_DIR =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\";

    // x87 math helpers (sqrt/abs/…) were falsely marked noreturn, truncating every
    // float-heavy function at its first sqrt call. Clear the flag so the export is
    // correct regardless of whether the fix was persisted to the project DB.
    private static final long[] FALSE_NORETURN = {0x401740L, 0x401750L, 0x4017a0L, 0x401630L};

    private PrintWriter fp;
    private DecompInterface decomp;
    private ConsoleTaskMonitor mon;
    private final Set<Long> done = new LinkedHashSet<>();

    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }

    private void clearFalseNoReturn() {
        for (long a : FALSE_NORETURN) {
            Function f = getFunctionAt(addr(a));
            if (f != null && f.hasNoReturn()) {
                f.setNoReturn(false);
                println("cleared noreturn on " + f.getName());
            }
        }
    }

    private String callersOf(Function f) {
        StringBuilder sb = new StringBuilder();
        int n = 0;
        for (Reference r : getReferencesTo(f.getEntryPoint())) {
            if (!r.getReferenceType().isCall()) continue;
            Function c = getFunctionContaining(r.getFromAddress());
            sb.append(String.format("0x%08x%s ", r.getFromAddress().getOffset(),
                c != null ? "(" + c.getName() + ")" : ""));
            if (++n >= 12) { sb.append("..."); break; }
        }
        return sb.toString().trim();
    }

    private void dump(Function f) {
        if (f == null) return;
        long key = f.getEntryPoint().getOffset();
        if (!done.add(key)) return;
        try {
            DecompileResults res = decomp.decompileFunction(f, 60, mon);
            fp.println("============================================================");
            fp.println(String.format("==== %s @0x%08x  size=%d  callers=[%s] ====",
                f.getName(), key, f.getBody().getNumAddresses(), callersOf(f)));
            if (res != null && res.decompileCompleted())
                fp.println(res.getDecompiledFunction().getC());
            else
                fp.println("  DECOMP FAIL");
        } catch (Exception e) { fp.println("  EXC " + e); }
    }

    @Override
    public void run() throws Exception {
        clearFalseNoReturn();
        String outPath = OUT_DIR + (CLUSTER_ONLY ? "texloader_cluster_decomp.txt"
                                                  : "all_functions_decomp.txt");
        new File(OUT_DIR).mkdirs();
        fp = new PrintWriter(new File(outPath), "UTF-8");
        decomp = new DecompInterface();
        decomp.openProgram(currentProgram);
        mon = new ConsoleTaskMonitor();
        FunctionManager fm = currentProgram.getFunctionManager();

        // Build the ordered work list.
        TreeMap<Long, Function> work = new TreeMap<>();
        if (CLUSTER_ONLY) {
            for (long s : SEEDS) {
                Function f = getFunctionContaining(addr(s));
                if (f != null) work.put(f.getEntryPoint().getOffset(), f);
                else fp.println(String.format("  (no fn @0x%08x)", s));
            }
        } else {
            // .text bounds
            long lo = Long.MAX_VALUE, hi = 0;
            for (MemoryBlock b : currentProgram.getMemory().getBlocks()) {
                if (b.isExecute()) {
                    lo = Math.min(lo, b.getStart().getOffset());
                    hi = Math.max(hi, b.getEnd().getOffset());
                }
            }
            for (Function f : fm.getFunctions(true)) {
                long off = f.getEntryPoint().getOffset();
                if (off >= lo && off <= hi && !f.isThunk()) work.put(off, f);
            }
        }

        fp.println(String.format("# %s export: %d functions", CLUSTER_ONLY ? "CLUSTER" : "ALL", work.size()));
        int i = 0, total = work.size();
        for (Function f : work.values()) {
            dump(f);
            if (++i % 50 == 0) { println("decompiled " + i + "/" + total); fp.flush(); }
            if (mon.isCancelled()) break;
        }
        decomp.dispose();
        fp.close();
        println("done -> " + outPath + "  (" + done.size() + " functions)");
    }
}
