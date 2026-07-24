// Decompile every function whose entry point is in [lo, hi). Args: <outPath> <loHex> <hiHex>
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import ghidra.util.task.ConsoleTaskMonitor;
import java.io.File;
import java.io.PrintWriter;

public class DecompileRange extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String out = args[0];
        long lo = Long.decode(args[1]), hi = Long.decode(args[2]);
        new File(out).getParentFile().mkdirs();
        DecompInterface dec = new DecompInterface(); dec.openProgram(currentProgram);
        ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
        PrintWriter fp = new PrintWriter(new File(out), "UTF-8");
        FunctionIterator it = currentProgram.getFunctionManager().getFunctions(true);
        int n = 0;
        while (it.hasNext()) {
            Function f = it.next();
            long e = f.getEntryPoint().getOffset();
            if (e < lo || e >= hi) continue;
            fp.println("============================================================");
            fp.println("==== " + f.getName() + " @" + f.getEntryPoint() + " ====");
            try {
                DecompileResults r = dec.decompileFunction(f, 120, mon);
                fp.println(r != null && r.decompileCompleted() ? r.getDecompiledFunction().getC() : "  DECOMP FAIL");
            } catch (Exception ex) { fp.println("  EXC " + ex); }
            fp.flush(); n++;
        }
        println("decompiled " + n + " functions in range");
        fp.close();
    }
}
