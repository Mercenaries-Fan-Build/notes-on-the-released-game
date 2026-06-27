// postScript: decompile every function and export to a single .c file.
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import java.io.*;

public class DecompileExport extends GhidraScript {
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String outPath = (args.length > 0) ? args[0]
            : "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra_x360\\xenon_decomp.c";
        DecompInterface di = new DecompInterface();
        di.openProgram(currentProgram);
        PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter(outPath), 1 << 20));
        FunctionIterator fns = currentProgram.getFunctionManager().getFunctions(true);
        int n = 0, ok = 0;
        long t0 = System.currentTimeMillis();
        while (fns.hasNext()) {
            if (monitor.isCancelled()) break;
            Function f = fns.next();
            out.println("==== " + f.getName() + " @" + f.getEntryPoint()
                    + "  size=" + f.getBody().getNumAddresses() + " ====");
            DecompileResults r = di.decompileFunction(f, 45, monitor);
            if (r != null && r.decompileCompleted()) {
                out.println(r.getDecompiledFunction().getC());
                ok++;
            } else {
                out.println("// decompile failed: " + (r != null ? r.getErrorMessage() : "null"));
            }
            if ((++n % 2000) == 0) {
                out.flush();
                println("  decompiled " + n + " (" + ((System.currentTimeMillis() - t0) / 1000) + "s, ok=" + ok + ")");
            }
        }
        out.close();
        di.dispose();
        println("DecompileExport: " + n + " functions, " + ok + " decompiled OK -> " + outPath);
    }
}
