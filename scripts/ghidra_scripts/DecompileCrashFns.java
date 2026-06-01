// Decompile the spatial-hash crash function + cell-index/loader code.
// Native Ghidra Java script (Ghidra 12.x dropped bundled Jython).
// Writes C decompilation + disassembly around the fault sites to
// output/_ghidra/crash_decomp.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Listing;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.util.HashSet;
import java.util.Set;

public class DecompileCrashFns extends GhidraScript {

    private static final long[] TARGET_VA = {
        0x0248BB60L, 0x00516B10L, 0x00516C00L, 0x0051812FL, 0x00516EF6L, 0x0063DA1FL
    };
    private static final String[] TARGET_LBL = {
        "spatial_crash_fn (read 0x248BB7C / write 0x248BBE2)",
        "spatial_cell_index_calc",
        "spatial_hash_insert",
        "spatial_loader_entry",
        "spatial_hash_benign_site",
        "entity_construct_stride"
    };
    private static final long[] FAULT_SITES = { 0x0248BB7CL, 0x0248BBE2L, 0x0248BB6DL };

    private static final String OUT_DIR =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra";

    private PrintWriter fp;

    private void w(String s) { fp.println(s); }

    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }

    @Override
    public void run() throws Exception {
        new File(OUT_DIR).mkdirs();
        File out = new File(OUT_DIR, "crash_decomp.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            FunctionManager fm = currentProgram.getFunctionManager();
            Listing listing = currentProgram.getListing();

            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();

            w("# Mercs2 spatial-hash crash decompilation");
            w("# program: " + currentProgram.getName());
            w("# image base: " + currentProgram.getImageBase());
            w("");

            String bar = new String(new char[78]).replace("\0", "=");
            Set<Long> seen = new HashSet<>();
            for (int i = 0; i < TARGET_VA.length; i++) {
                long va = TARGET_VA[i];
                Address a = addr(va);
                Function fn = fm.getFunctionContaining(a);
                w(bar);
                w(String.format("TARGET 0x%08x  %s", va, TARGET_LBL[i]));
                if (fn == null) {
                    w("  (no function defined here)");
                    w("");
                    continue;
                }
                long key = fn.getEntryPoint().getOffset();
                if (seen.contains(key)) {
                    w("  (same function as a previous target: " + fn.getName()
                        + " @ " + fn.getEntryPoint() + ")");
                    w("");
                    continue;
                }
                seen.add(key);
                w("  function: " + fn.getName() + "  entry=" + fn.getEntryPoint()
                    + "  size=" + fn.getBody().getNumAddresses());
                try {
                    DecompileResults res = decomp.decompileFunction(fn, 60, mon);
                    if (res != null && res.decompileCompleted()) {
                        w("");
                        w(res.getDecompiledFunction().getC());
                    } else {
                        w("  DECOMP FAILED: " + (res != null ? res.getErrorMessage() : "no result"));
                    }
                } catch (Exception e) {
                    w("  DECOMP EXC: " + e);
                }
                w("");
            }

            w(bar);
            w("DISASSEMBLY around fault sites (+/- 0x30):");
            for (long site : FAULT_SITES) {
                w("");
                w(String.format("--- fault 0x%08x ---", site));
                Address cur = addr(site - 0x30);
                Address end = addr(site + 0x30);
                while (cur != null && cur.getOffset() <= end.getOffset()) {
                    Instruction ins = listing.getInstructionAt(cur);
                    if (ins == null) {
                        cur = cur.add(1);
                        continue;
                    }
                    String marker = (cur.getOffset() == site) ? "  >>>" : "     ";
                    w(marker + " " + cur + "  " + ins);
                    Instruction nxt = ins.getNext();
                    if (nxt == null) break;
                    cur = nxt.getAddress();
                }
            }
            decomp.dispose();
        } finally {
            fp.close();
        }
        println("wrote " + out.getAbsolutePath());
    }
}
