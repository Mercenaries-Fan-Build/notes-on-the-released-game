// Find defined strings matching given text, list xrefs, and decompile each referencing function.
// Args: <outPath> <substr> ...
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.DataIterator;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.Reference;
import ghidra.util.task.ConsoleTaskMonitor;
import java.io.File;
import java.io.PrintWriter;
import java.util.HashSet;

public class DecompStringRefs extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String out = args[0];
        new File(out).getParentFile().mkdirs();
        DecompInterface dec = new DecompInterface(); dec.openProgram(currentProgram);
        ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
        PrintWriter fp = new PrintWriter(new File(out), "UTF-8");
        HashSet<String> decompiled = new HashSet<>();
        DataIterator it = currentProgram.getListing().getDefinedData(true);
        while (it.hasNext()) {
            Data d = it.next();
            Object v = d.getValue();
            if (!(v instanceof String)) continue;
            String s = (String) v;
            for (int i = 1; i < args.length; i++) {
                if (!s.contains(args[i])) continue;
                Address sa = d.getAddress();
                fp.println("############################################################");
                fp.println("## STRING \"" + s + "\" @" + sa);
                for (Reference r : getReferencesTo(sa)) {
                    Function f = getFunctionContaining(r.getFromAddress());
                    if (f == null) { fp.println("  ref from " + r.getFromAddress() + " (no func)"); continue; }
                    String key = f.getEntryPoint().toString();
                    fp.println("  ref from " + f.getName() + "@" + key);
                    if (!decompiled.add(key)) continue;
                    try {
                        DecompileResults dr = dec.decompileFunction(f, 150, mon);
                        fp.println(dr != null && dr.decompileCompleted() ? dr.getDecompiledFunction().getC()
                                                                         : "  DECOMP FAIL");
                    } catch (Exception e) { fp.println("  EXC " + e); }
                    fp.flush(); println("decompiled ref @" + key);
                }
            }
        }
        fp.close();
    }
}
