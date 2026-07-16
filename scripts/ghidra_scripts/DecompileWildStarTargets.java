// Generic: name every function from WildStar_d.map, then decompile a target set passed as args.
// Args: <outPath> <VA:name> <VA:name> ...   (VA hex like 0x825c86e8)
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

public class DecompileWildStarTargets extends GhidraScript {
    private static final String MAP =
        "C:\\Users\\Shadow\\Desktop\\notes-on-reversing-the-sabetour\\game-files\\symbols\\WildStar_d.map";
    private static final Pattern LINE =
        Pattern.compile("^\\s+[0-9a-f]{4}:[0-9a-f]{8}\\s+(\\S+)\\s+([0-9a-f]{8})\\s+f\\b");

    private String readable(String mangled) {
        String s = mangled;
        if (s.startsWith("?")) {
            String body = s.substring(1);
            if (body.startsWith("?")) body = body.replaceFirst("^\\?[0-9A-Za-z_]+", "spec");
            int at = body.indexOf("@@"); if (at >= 0) body = body.substring(0, at);
            String[] segs = body.split("@"); List<String> p = new ArrayList<>();
            for (int i = segs.length - 1; i >= 0; i--) if (!segs[i].isEmpty()) p.add(segs[i]);
            s = String.join("__", p);
        }
        s = s.replaceAll("[^A-Za-z0-9_]", "_");
        if (s.length() > 180) s = s.substring(0, 180);
        return s.isEmpty() ? "sym" : s;
    }

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String out = args[0];
        new File(out).getParentFile().mkdirs();
        int named = 0;
        try (BufferedReader br = new BufferedReader(new FileReader(MAP))) {
            String ln;
            while ((ln = br.readLine()) != null) {
                Matcher m = LINE.matcher(ln); if (!m.find()) continue;
                String mangled = m.group(1);
                if (!mangled.startsWith("?") && !mangled.startsWith("_")) continue;
                long va = Long.parseLong(m.group(2), 16); Address a = toAddr(va);
                if (a == null) continue;
                try {
                    Function f = getFunctionAt(a);
                    if (f == null) f = createFunction(a, null);
                    if (f != null) { f.setName(readable(mangled) + "_" + Long.toHexString(va), SourceType.IMPORTED); named++; }
                } catch (Exception e) {}
            }
        }
        println("map naming done: " + named);
        DecompInterface dec = new DecompInterface(); dec.openProgram(currentProgram);
        ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
        PrintWriter fp = new PrintWriter(new File(out), "UTF-8");
        for (int i = 1; i < args.length; i++) {
            String[] kv = args[i].split(":", 2);
            long va = Long.decode(kv[0]); String nm = kv.length > 1 ? kv[1] : kv[0];
            Address a = toAddr(va); Function f = getFunctionAt(a);
            fp.println("============================================================");
            fp.println("==== " + nm + " @" + kv[0] + " ====");
            if (f == null) f = createFunction(a, nm);
            if (f == null) { fp.println("  NO FUNCTION"); continue; }
            try {
                DecompileResults r = dec.decompileFunction(f, 120, mon);
                fp.println(r != null && r.decompileCompleted() ? r.getDecompiledFunction().getC()
                                                               : "  DECOMP FAIL: " + (r!=null?r.getErrorMessage():"null"));
            } catch (Exception e) { fp.println("  EXC " + e); }
            fp.flush(); println("decompiled " + nm);
        }
        dec.dispose(); fp.close(); println("done -> " + out);
    }
}
