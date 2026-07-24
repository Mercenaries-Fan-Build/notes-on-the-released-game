// Decompile a set of VAs (no map dependency). For each target also lists its callers.
// Args: <outPath> <VA:name> ...
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.Reference;
import ghidra.util.task.ConsoleTaskMonitor;
import java.io.File;
import java.io.PrintWriter;

public class DecompileVAs extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String out = args[0];
        new File(out).getParentFile().mkdirs();
        DecompInterface dec = new DecompInterface(); dec.openProgram(currentProgram);
        ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
        PrintWriter fp = new PrintWriter(new File(out), "UTF-8");
        for (int i = 1; i < args.length; i++) {
            String[] kv = args[i].split(":", 2);
            long va = Long.decode(kv[0]); String nm = kv.length > 1 ? kv[1] : kv[0];
            Address a = toAddr(va);
            fp.println("============================================================");
            fp.println("==== " + nm + " @" + kv[0] + " ====");
            Function f = getFunctionAt(a);
            if (f == null) f = createFunction(a, nm);
            if (f == null) { fp.println("  NO FUNCTION"); fp.flush(); continue; }
            // callers
            StringBuilder cs = new StringBuilder("  callers: ");
            for (Reference r : getReferencesTo(f.getEntryPoint())) {
                Function cf = getFunctionContaining(r.getFromAddress());
                if (cf != null) cs.append(cf.getName()).append("@").append(cf.getEntryPoint()).append(" ");
            }
            fp.println(cs.toString());
            try {
                DecompileResults r = dec.decompileFunction(f, 150, mon);
                fp.println(r != null && r.decompileCompleted() ? r.getDecompiledFunction().getC()
                                                               : "  DECOMP FAIL: " + (r!=null?r.getErrorMessage():"null"));
            } catch (Exception e) { fp.println("  EXC " + e); }
            fp.flush(); println("decompiled " + nm);
        }
        fp.close();
    }
}
