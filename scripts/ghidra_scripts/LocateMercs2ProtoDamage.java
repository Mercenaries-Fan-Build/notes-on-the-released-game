// Locate + decompile the Mercs2 damage/explosion SOLVER in the Jul-08 Xbox360 devkit prototype
// (Mercs2_Xenon_P, Xenon BE PPC, base 0x82000000, DECOMPILABLE — no SecuROM). The solver fn names
// survive as STRINGS; we xref them to their code/binding-table sites and decompile.
//
// Run as headless postScript AFTER -analyze. Output -> output/jul08_prototype/mercs2_proto_damage_decomp.txt
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.mem.Memory;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Reference;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashSet;
import java.util.Set;

public class LocateMercs2ProtoDamage extends GhidraScript {
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\jul08_prototype\\mercs2_proto_damage_decomp.txt";
    private static final String[] TARGETS = {
        "ApplyDamageToPrimaryHealth", "ApplyDamageToNodeHealth", "ApplyExplosionToBodies",
        "ApplyExplosionToPrimary", "ApplyExplosion", "ApplyDamage",
        "PhysicsCreateExplosion", "RuntimeHealth", "DamageKey",
    };

    private PrintWriter fp;
    private DecompInterface dec;
    private ConsoleTaskMonitor mon;
    private final Set<Long> decompiled = new LinkedHashSet<>();

    private void decompAt(Address a, String why) {
        Function f = getFunctionContaining(a);
        if (f == null) { fp.println("    (no function containing " + a + " — " + why + ")"); return; }
        if (!decompiled.add(f.getEntryPoint().getOffset())) {
            fp.println("    -> " + f.getName() + " @" + f.getEntryPoint() + " (already dumped)"); return;
        }
        fp.println("    -> DECOMP " + f.getName() + " @" + f.getEntryPoint() + " (" + why + ")");
        try {
            DecompileResults r = dec.decompileFunction(f, 120, mon);
            fp.println(r != null && r.decompileCompleted() ? r.getDecompiledFunction().getC()
                                                           : "    DECOMP FAIL");
        } catch (Exception e) { fp.println("    EXC " + e); }
    }

    @Override
    public void run() throws Exception {
        new File(OUT).getParentFile().mkdirs();
        fp = new PrintWriter(new File(OUT), "UTF-8");
        dec = new DecompInterface(); dec.openProgram(currentProgram);
        mon = new ConsoleTaskMonitor();
        Memory mem = currentProgram.getMemory();

        for (String s : TARGETS) {
            fp.println("============================================================");
            fp.println("==== STRING: \"" + s + "\" ====");
            byte[] pat = (s + "\0").getBytes(StandardCharsets.US_ASCII);
            // find every occurrence of the NUL-terminated string across memory
            int hits = 0;
            for (MemoryBlock b : mem.getBlocks()) {
                if (!b.isInitialized()) continue;
                Address at = b.getStart();
                while (at != null && at.compareTo(b.getEnd()) < 0) {
                    Address found = mem.findBytes(at, b.getEnd(), pat, null, true, mon);
                    if (found == null) break;
                    hits++;
                    fp.println("  @ " + found + "  refs:");
                    Reference[] refs = getReferencesTo(found);
                    if (refs.length == 0) fp.println("    (no direct refs — may be reached via +offset or table)");
                    for (Reference r : refs) {
                        Address from = r.getFromAddress();
                        fp.println("    from " + from + " [" + r.getReferenceType() + "]");
                        decompAt(from, "xref to \"" + s + "\"");
                    }
                    try { at = found.add(1); } catch (Exception e) { break; }
                }
            }
            if (hits == 0) fp.println("  (string not found)");
            println("scanned \"" + s + "\" hits=" + hits);
            fp.flush();
        }
        dec.dispose(); fp.close();
        println("done -> " + OUT);
    }
}
