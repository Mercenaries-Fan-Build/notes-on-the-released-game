// Decompile the suspects around the class-122 (512-byte) pool overflow caught by poolguard:
//   - the 16-byte alloc flood callers 0x67A9C8 / 0x67AA8F / 0x67AB2D (FUN_0067xxxx subsystem)
//   - 0x414B0B (ring-adjacency candidate; near the PHY2 name-lookup crash 0x414B4C)
//   - 0x414AF0-ish copy loop neighbourhood (the 0x41AFB6 victim earlier lived in 0x41xxxx)
// The overflower allocates a 512-byte buffer and writes one u32 past its end; these are the
// call sites to read. Writes output/_ghidra/overflower_decomp.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceManager;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.util.HashSet;
import java.util.Set;

public class DecompileOverflower extends GhidraScript {

    private static final long[] TARGET_VA = {
        0x0067A9C8L, // 16B alloc flood caller A
        0x0067AA8FL, // 16B alloc flood caller B
        0x0067AB2DL, // 16B alloc flood caller C
        0x00414B0BL, // ring-adjacency candidate (near PHY2 crash 0x414B4C)
    };
    private static final String[] TARGET_LBL = {
        "flood caller A 0x67A9C8 (16B allocs)",
        "flood caller B 0x67AA8F (16B allocs)",
        "flood caller C 0x67AB2D (16B allocs)",
        "adjacency candidate 0x414B0B",
    };
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
        File out = new File(OUT_DIR, "overflower_decomp.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            FunctionManager fm = currentProgram.getFunctionManager();
            ReferenceManager rm = currentProgram.getReferenceManager();
            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();

            w("# Mercs2 class-122 (512-byte) pool overflower suspects");
            w("# program: " + currentProgram.getName());
            w("");
            String bar = new String(new char[78]).replace("\0", "=");

            Set<Long> seen = new HashSet<>();
            for (int i = 0; i < TARGET_VA.length; i++) {
                long va = TARGET_VA[i];
                Function fn = fm.getFunctionContaining(addr(va));
                w(bar);
                w(String.format("TARGET 0x%08x  %s", va, TARGET_LBL[i]));
                if (fn == null) { w("  (no function defined)"); w(""); continue; }
                long key = fn.getEntryPoint().getOffset();
                w("  function: " + fn.getName() + "  entry=" + fn.getEntryPoint()
                    + "  size=" + fn.getBody().getNumAddresses());
                int nc = 0;
                for (Reference r : rm.getReferencesTo(fn.getEntryPoint())) {
                    if (!r.getReferenceType().isCall()) continue;
                    Function cf = fm.getFunctionContaining(r.getFromAddress());
                    w(String.format("    caller 0x%08x %s", r.getFromAddress().getOffset(),
                        cf != null ? cf.getName() : "(no fn)"));
                    if (++nc >= 10) { w("    ..."); break; }
                }
                if (seen.contains(key)) { w("  (already decompiled above)"); w(""); continue; }
                seen.add(key);
                try {
                    DecompileResults res = decomp.decompileFunction(fn, 60, mon);
                    if (res != null && res.decompileCompleted()) {
                        w(""); w(res.getDecompiledFunction().getC());
                    } else {
                        w("  DECOMP FAILED: " + (res != null ? res.getErrorMessage() : "no result"));
                    }
                } catch (Exception e) { w("  DECOMP EXC: " + e); }
                w("");
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("wrote " + out.getAbsolutePath());
    }
}
