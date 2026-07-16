// Decompile the WildStar (The Saboteur, Xbox360 devkit, BE PPC) damage/explosion/destruction
// SOLVER cluster with names applied from the linker .map. This is the Mercs2 "wall" named.
//
// Pipeline: (1) parse WildStar_d.map, create+name every code (' f ') symbol so call sites resolve;
// (2) decompile the hand-picked solver target set to output/_ghidra_saboteur/wildstar_damage_decomp.txt.
//
// Run as a headless postScript after -analyze. Map + output paths are hardcoded.
// @category Saboteur
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.SourceType;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class DecompileWildStarDamage extends GhidraScript {
    private static final String MAP =
        "C:\\Users\\Shadow\\Desktop\\notes-on-reversing-the-sabetour\\game-files\\symbols\\WildStar_d.map";
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra_saboteur\\wildstar_damage_decomp.txt";

    // authoritative solver targets: {VA, readableName}
    private static final String[][] TARGETS = {
        {"0x82671ef0","WSDamageable__ApplyDamage"},
        {"0x82671e80","WSDamageable__SetDamageableProperty"},
        {"0x82432c20","WSDamageable__GetHealth"},
        {"0x82432c08","WSDamageable__SetHealth"},
        {"0x82432bf0","WSDamageable__IsDamageableAlive"},
        {"0x826720a0","WSDamageable__Die"},
        {"0x82672108","WSDamageable__SetupDamagableNode"},
        {"0x826724c0","WSDamageable__AncestorDamaged"},
        {"0x82672500","WSDamageable__AncestorDied"},
        {"0x826723d0","WSDamageable__TellChildrenAncestorDamaged"},
        {"0x82672448","WSDamageable__TellChildrenAncestorDied"},
        {"0x824653e0","WSExplosion__AddVictim"},
        {"0x82465b60","WSExplosion__Update"},
        {"0x824665e8","WSExplosion__CreateExplosion"},
        {"0x82466510","WSExplosion__CreateExplosionDeferred"},
        {"0x824663d0","WSExplosion__UpdateDeferred"},
        {"0x82467318","WSExplosion__IsVictimShieldedFromExplosion"},
        {"0x824672c8","WSExplosion__VictimShouldWait"},
        {"0x824650e0","WSExplosion__Init"},
        {"0x82678a50","WSDestructable__UpdatePhysicsObjects"},
        {"0x829e8cb0","WSPhysicsObject__ApplyHitForce"},
        {"0x824f0d00","WSHuman__ApplyDamage"},
        {"0x824f0618","WSHuman__ApplyHitDamage"},
        {"0x8249bed8","WSProp__ApplyDamage"},
        {"0x825d5538","WSVehicle__ApplyDamage"},
        {"0x826c1510","WSOrdnanceReactionHelper__ctor"},
        {"0x82503ce0","WSDamageDesc__BulletDamage"},
    };

    // ' <sec>:<off>   <mangled>   <va> f [i] <obj>'  -> capture mangled + va, only ' f ' (function)
    private static final Pattern LINE =
        Pattern.compile("^\\s+[0-9a-f]{4}:[0-9a-f]{8}\\s+(\\S+)\\s+([0-9a-f]{8})\\s+f\\b");

    private String readable(String mangled) {
        // ?name@Class@Ns@@... -> Ns__Class__name ; strip template noise, sanitize
        String s = mangled;
        if (s.startsWith("?")) {
            String body = s.substring(1);
            if (body.startsWith("?")) { // special (ctor/dtor/op/vftable): keep a tag
                body = body.replaceFirst("^\\?[0-9A-Za-z_]+", "spec");
            }
            int at = body.indexOf("@@");
            if (at >= 0) body = body.substring(0, at);
            String[] segs = body.split("@");
            List<String> parts = new ArrayList<>();
            for (int i = segs.length - 1; i >= 0; i--) if (!segs[i].isEmpty()) parts.add(segs[i]);
            s = String.join("__", parts);
        }
        s = s.replaceAll("[^A-Za-z0-9_]", "_");
        if (s.length() > 180) s = s.substring(0, 180);
        return s.isEmpty() ? "sym" : s;
    }

    @Override
    public void run() throws Exception {
        new File(OUT).getParentFile().mkdirs();
        // 1) name everything from the map so call sites read cleanly
        int named = 0, made = 0;
        try (BufferedReader br = new BufferedReader(new FileReader(MAP))) {
            String ln;
            while ((ln = br.readLine()) != null) {
                Matcher m = LINE.matcher(ln);
                if (!m.find()) continue;
                String mangled = m.group(1);
                if (!mangled.startsWith("?") && !mangled.startsWith("_")) continue;
                long va = Long.parseLong(m.group(2), 16);
                Address a = toAddr(va);
                if (a == null) continue;
                try {
                    Function f = getFunctionAt(a);
                    if (f == null) { f = createFunction(a, null); if (f != null) made++; }
                    if (f != null) {
                        String nm = readable(mangled) + "_" + Long.toHexString(va);
                        f.setName(nm, SourceType.IMPORTED);
                        named++;
                    }
                } catch (Exception e) { /* skip bad addrs */ }
                if ((named % 5000) == 0 && named > 0) println("named " + named + " (created " + made + ")");
            }
        }
        println("map naming done: named=" + named + " created=" + made);

        // 2) decompile the solver target set
        DecompInterface dec = new DecompInterface();
        dec.openProgram(currentProgram);
        ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
        PrintWriter fp = new PrintWriter(new File(OUT), "UTF-8");
        fp.println("# WildStar (The Saboteur Xbox360 devkit, BE PPC) damage/explosion/destruction solver");
        fp.println("# names applied from WildStar_d.map; " + TARGETS.length + " target functions\n");
        for (String[] t : TARGETS) {
            long va = Long.decode(t[0]);
            Address a = toAddr(va);
            Function f = getFunctionAt(a);
            fp.println("============================================================");
            fp.println("==== " + t[1] + " @" + t[0] + " ====");
            if (f == null) { f = createFunction(a, t[1]); }
            if (f == null) { fp.println("  NO FUNCTION AT ADDR"); continue; }
            try {
                DecompileResults r = dec.decompileFunction(f, 120, mon);
                if (r != null && r.decompileCompleted())
                    fp.println(r.getDecompiledFunction().getC());
                else
                    fp.println("  DECOMP FAIL: " + (r != null ? r.getErrorMessage() : "null"));
            } catch (Exception e) { fp.println("  EXC " + e); }
            fp.flush();
            println("decompiled " + t[1]);
        }
        dec.dispose();
        fp.close();
        println("done -> " + OUT);
    }
}
