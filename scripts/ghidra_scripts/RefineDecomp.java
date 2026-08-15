// Additive "comprehensive" top-up for the corpus Ghidra dump.
// Opens the existing analyzed mercs2_unpacked.exe program READ-ONLY (-noanalysis -readOnly,
// nothing is written back to the curated project) and re-decompiles two gap sets:
//   (1) the 167 functions that came out "DECOMP FAIL" in the 60s export, retried at 180s;
//   (2) the 3 SecuROM stolen-prologue functions that mercs2_nodrm_v3.exe restores inline
//       (0x5e9de0 / 0x5e9f40 restored to `55 8bec 83e4`; 0x6d5640 to `33c0 c3`). We patch
//       only the first 5 bytes in memory (bytes 6+ already match the dump), then create+decompile.
// Emits the SAME header format as DecompileAllByName so the result splices into the dump:
//   ==== <name> @0xADDR  size=N  callers=[...] ====
// Writes output/_ghidra/comprehensive_patch_decomp.txt
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.Reference;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

public class RefineDecomp extends GhidraScript {
    private static final String OUT_DIR =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\";
    private static final String TARGETS = OUT_DIR + "refine_targets.txt";
    private static final int TIMEOUT = 180;

    // nodrm_v3-restored prologues (first 5 bytes only; the rest already match the dump image).
    private static final long[]   PATCH_ADDR  = { 0x005e9de0L, 0x005e9f40L, 0x006d5640L };
    private static final byte[][] PATCH_BYTES = {
        { (byte)0x55, (byte)0x8b, (byte)0xec, (byte)0x83, (byte)0xe4 },
        { (byte)0x55, (byte)0x8b, (byte)0xec, (byte)0x83, (byte)0xe4 },
        { (byte)0x33, (byte)0xc0, (byte)0xc3, (byte)0xcc, (byte)0xcc },
    };

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

    private void emit(Function f) {
        try {
            DecompileResults res = decomp.decompileFunction(f, TIMEOUT, mon);
            fp.println("============================================================");
            fp.println(String.format("==== %s @0x%08x  size=%d  callers=[%s] ====",
                f.getName(), f.getEntryPoint().getOffset(),
                f.getBody().getNumAddresses(), callersOf(f)));
            if (res != null && res.decompileCompleted())
                fp.println(res.getDecompiledFunction().getC());
            else
                fp.println("  DECOMP FAIL");
        } catch (Exception e) { fp.println("  EXC " + e); }
    }

    @Override
    public void run() throws Exception {
        new File(OUT_DIR).mkdirs();
        fp = new PrintWriter(new File(OUT_DIR + "comprehensive_patch_decomp.txt"), "UTF-8");
        decomp = new DecompInterface();
        decomp.openProgram(currentProgram);
        mon = new ConsoleTaskMonitor();

        // (2) Restore the 3 nodrm_v3 prologues, then create functions there.
        for (int i = 0; i < PATCH_ADDR.length; i++) {
            Address a = toAddr(PATCH_ADDR[i]);
            try {
                Function old = getFunctionAt(a);
                if (old != null) removeFunction(old);
                clearListing(a, a.add(32));
                setBytes(a, PATCH_BYTES[i]);
                disassemble(a);
                Function f = createFunction(a, null);
                if (f == null) f = getFunctionContaining(a);
                if (f != null) { emit(f); println("patched+decompiled " + f.getName()); }
                else { fp.println("  (no fn created @0x" + Long.toHexString(PATCH_ADDR[i]) + ")");
                       println("FAILED to create fn @0x" + Long.toHexString(PATCH_ADDR[i])); }
            } catch (Exception e) {
                fp.println("  PATCH EXC @0x" + Long.toHexString(PATCH_ADDR[i]) + " " + e);
                println("patch exc @0x" + Long.toHexString(PATCH_ADDR[i]) + ": " + e);
            }
        }

        // (1) Retry the DECOMP FAIL targets at a longer timeout.
        List<Long> targets = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(TARGETS))) {
            String line;
            while ((line = br.readLine()) != null) {
                line = line.trim();
                if (line.isEmpty()) continue;
                targets.add(Long.parseLong(line.replaceFirst("^0x", ""), 16));
            }
        }
        int i = 0, ok = 0, total = targets.size();
        for (long va : targets) {
            Function f = getFunctionContaining(toAddr(va));
            if (f == null) { fp.println("  (no fn @0x" + Long.toHexString(va) + ")"); continue; }
            DecompileResults res = decomp.decompileFunction(f, TIMEOUT, mon);
            fp.println("============================================================");
            fp.println(String.format("==== %s @0x%08x  size=%d  callers=[%s] ====",
                f.getName(), f.getEntryPoint().getOffset(),
                f.getBody().getNumAddresses(), callersOf(f)));
            if (res != null && res.decompileCompleted()) { fp.println(res.getDecompiledFunction().getC()); ok++; }
            else fp.println("  DECOMP FAIL");
            if (++i % 20 == 0) { println("refined " + i + "/" + total + " (ok=" + ok + ")"); fp.flush(); }
            if (mon.isCancelled()) break;
        }
        decomp.dispose();
        fp.close();
        println("RefineDecomp done: " + i + " fail-targets retried, " + ok + " now OK; 3 prologue patches attempted.");
    }
}
