// Decompile every function that CALLs the target address(es). Args: <outPath> <addrHex> ...
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.Reference;
import ghidra.util.task.ConsoleTaskMonitor;
import java.io.File;
import java.io.PrintWriter;
import java.util.HashSet;

public class DecompCallersOf extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String out = args[0];
        new File(out).getParentFile().mkdirs();
        DecompInterface dec = new DecompInterface(); dec.openProgram(currentProgram);
        ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
        PrintWriter fp = new PrintWriter(new File(out), "UTF-8");
        HashSet<String> done = new HashSet<>();
        for (int i = 1; i < args.length; i++) {
            Address ta = toAddr(Long.decode(args[i]));
            fp.println("################ callers of " + ta + " ################");
            for (Reference r : getReferencesTo(ta)) {
                Function f = getFunctionContaining(r.getFromAddress());
                if (f == null) { fp.println("  ref " + r.getReferenceType() + " from " + r.getFromAddress() + " (no fn)"); continue; }
                String key = f.getEntryPoint().toString();
                fp.println("  " + r.getReferenceType() + " from " + f.getName() + "@" + key);
                if (!done.add(key)) continue;
                try {
                    DecompileResults dr = dec.decompileFunction(f, 150, mon);
                    fp.println(dr != null && dr.decompileCompleted() ? dr.getDecompiledFunction().getC() : "  DECOMP FAIL");
                } catch (Exception e) { fp.println("  EXC " + e); }
                fp.flush();
            }
        }
        fp.close();
        println("done");
    }
}
