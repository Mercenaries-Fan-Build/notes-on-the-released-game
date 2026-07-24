// Hard-fix the Xbox360 __savegprlr/__restgprlr/__savefpr/__restfpr helpers (which Ghidra marks
// no-return, truncating big-frame functions to just the prologue bl), then re-disassemble + decompile
// the target VAs. Names all map symbols first for readability.
// Args: <outPath> <VA:name> ...
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

public class DecompileWSHardFix extends GhidraScript {
    private static final String MAP =
        "C:\\Users\\Shadow\\Desktop\\notes-on-reversing-the-sabetour\\game-files\\symbols\\WildStar_d.map";
    private static final Pattern LINE =
        Pattern.compile("^\\s+[0-9a-f]{4}:[0-9a-f]{8}\\s+(\\S+)\\s+([0-9a-f]{8})\\s+f\\b");
    // helper lines have NO 'f' flag: "<sect>:<off>  __savegprlr_22  831c3f40  LIBCMTD:crtgpr.obj"
    private static final Pattern HELPER =
        Pattern.compile("(__(?:save|rest)(?:gpr|fpr|vmx)\\w*)\\s+([0-9a-f]{8})\\b");

    private String readable(String mangled) {
        String s = mangled;
        if (s.startsWith("?")) {
            String body = s.substring(1);
            int at = body.indexOf("@@"); if (at >= 0) body = body.substring(0, at);
            String[] segs = body.split("@"); List<String> p = new ArrayList<>();
            for (int i = segs.length - 1; i >= 0; i--) if (!segs[i].isEmpty()) p.add(segs[i]);
            s = String.join("__", p);
        }
        s = s.replaceAll("[^A-Za-z0-9_]", "_");
        if (s.length() > 160) s = s.substring(0, 160);
        return s.isEmpty() ? "sym" : s;
    }

    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String out = args[0];
        new File(out).getParentFile().mkdirs();
        int named = 0, fixed = 0;
        try (BufferedReader br = new BufferedReader(new FileReader(MAP))) {
            String ln;
            while ((ln = br.readLine()) != null) {
                Matcher hm = HELPER.matcher(ln);
                if (hm.find()) {
                    long va = Long.parseLong(hm.group(2), 16); Address a = toAddr(va);
                    if (a != null) {
                        try {
                            Function f = getFunctionAt(a);
                            if (f == null) { disassemble(a); f = createFunction(a, hm.group(1)); }
                            if (f != null) { f.setNoReturn(false); fixed++; }
                        } catch (Exception e) {}
                    }
                    continue;
                }
                Matcher m = LINE.matcher(ln); if (!m.find()) continue;
                String mangled = m.group(1);
                if (!mangled.startsWith("?")) continue;
                long va = Long.parseLong(m.group(2), 16); Address a = toAddr(va);
                if (a == null) continue;
                try {
                    Function f = getFunctionAt(a);
                    if (f == null) f = createFunction(a, null);
                    if (f != null) { f.setName(readable(mangled) + "_" + Long.toHexString(va), SourceType.IMPORTED); named++; }
                } catch (Exception e) {}
            }
        }
        println("named=" + named + " helpers_fixed=" + fixed);

        DecompInterface dec = new DecompInterface(); dec.openProgram(currentProgram);
        ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
        PrintWriter fp = new PrintWriter(new File(out), "UTF-8");
        for (int i = 1; i < args.length; i++) {
            String[] kv = args[i].split(":", 2);
            long va = Long.decode(kv[0]); String nm = kv.length > 1 ? kv[1] : kv[0];
            Address a = toAddr(va);
            fp.println("============================================================");
            fp.println("==== " + nm + " @" + kv[0] + " ====");
            // force re-disassembly of the (now un-truncated) body, then re-create the function
            try {
                Function old = getFunctionAt(a);
                if (old != null) removeFunctionAt(a);
                disassemble(a);
                Function f = createFunction(a, nm);
                if (f == null) f = getFunctionContaining(a);
                if (f == null) { fp.println("  NO FUNCTION"); fp.flush(); continue; }
                DecompileResults r = dec.decompileFunction(f, 200, mon);
                fp.println(r != null && r.decompileCompleted() ? r.getDecompiledFunction().getC()
                                                               : "  DECOMP FAIL: " + (r!=null?r.getErrorMessage():"null"));
            } catch (Exception e) { fp.println("  EXC " + e); }
            fp.flush(); println("decompiled " + nm);
        }
        fp.close();
    }
}
