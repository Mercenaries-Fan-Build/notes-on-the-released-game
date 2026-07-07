// Export decompiled C for every FUN_* in .text, named per-program so multiple
// builds can be analyzed without clobbering each other's output.
// Writes output/_ghidra/<programName>_decomp.txt
// (Sibling of DecompileAllFunctions.java, which hardcodes all_functions_decomp.txt.)
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Reference;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.util.TreeMap;

public class DecompileAllByName extends GhidraScript {
    private static final String OUT_DIR =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\";

    // x87 math helpers (sqrt/abs/…) were falsely marked noreturn, truncating every
    // float-heavy function at its first sqrt call. Clear the flag so the export is
    // correct regardless of whether the fix was persisted to the project DB.
    private static final long[] FALSE_NORETURN = {0x401740L, 0x401750L, 0x4017a0L, 0x401630L};

    private void clearFalseNoReturn() {
        for (long a : FALSE_NORETURN) {
            Function f = getFunctionAt(currentProgram.getAddressFactory()
                .getDefaultAddressSpace().getAddress(a));
            if (f != null && f.hasNoReturn()) {
                f.setNoReturn(false);
                println("cleared noreturn on " + f.getName());
            }
        }
    }

    private PrintWriter fp;
    private DecompInterface decomp;
    private ConsoleTaskMonitor mon;

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
        try {
            DecompileResults res = decomp.decompileFunction(f, 60, mon);
            fp.println("============================================================");
            fp.println(String.format("==== %s @0x%08x  size=%d  callers=[%s] ====",
                f.getName(), f.getEntryPoint().getOffset(), f.getBody().getNumAddresses(), callersOf(f)));
            if (res != null && res.decompileCompleted())
                fp.println(res.getDecompiledFunction().getC());
            else
                fp.println("  DECOMP FAIL");
        } catch (Exception e) { fp.println("  EXC " + e); }
    }

    @Override
    public void run() throws Exception {
        clearFalseNoReturn();
        String outPath = OUT_DIR + currentProgram.getName() + "_decomp.txt";
        new File(OUT_DIR).mkdirs();
        fp = new PrintWriter(new File(outPath), "UTF-8");
        decomp = new DecompInterface();
        decomp.openProgram(currentProgram);
        mon = new ConsoleTaskMonitor();
        FunctionManager fm = currentProgram.getFunctionManager();

        long lo = Long.MAX_VALUE, hi = 0;
        for (MemoryBlock b : currentProgram.getMemory().getBlocks()) {
            if (b.isExecute()) {
                lo = Math.min(lo, b.getStart().getOffset());
                hi = Math.max(hi, b.getEnd().getOffset());
            }
        }
        TreeMap<Long, Function> work = new TreeMap<>();
        for (Function f : fm.getFunctions(true)) {
            long off = f.getEntryPoint().getOffset();
            if (off >= lo && off <= hi && !f.isThunk()) work.put(off, f);
        }

        fp.println(String.format("# %s ALL export: %d functions", currentProgram.getName(), work.size()));
        int i = 0, total = work.size();
        for (Function f : work.values()) {
            dump(f);
            if (++i % 50 == 0) { println("decompiled " + i + "/" + total); fp.flush(); }
            if (mon.isCancelled()) break;
        }
        decomp.dispose();
        fp.close();
        println("done -> " + outPath + "  (" + total + " functions)");
    }
}
