// JC2ExportAll.java — headless post-analysis export for Just Cause 2.
// Dumps (1) full symbol/function table and (2) decompiled C for every function
// into files under the directory given as the first script arg.
// @category JC2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.symbol.Symbol;
import ghidra.program.model.symbol.SymbolTable;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.PrintWriter;

public class JC2ExportAll extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String outDir = (args.length > 0) ? args[0] : ".";
        FunctionManager fm = currentProgram.getFunctionManager();

        // 1) symbol/function table
        PrintWriter sym = new PrintWriter(new BufferedWriter(new FileWriter(outDir + "/jc2_functions.txt")));
        int fcount = 0;
        for (Function f : fm.getFunctions(true)) {
            sym.println(String.format("%s\t%s\t%d", f.getEntryPoint(), f.getName(true), f.getBody().getNumAddresses()));
            fcount++;
        }
        sym.close();
        println("wrote " + fcount + " functions to jc2_functions.txt");

        // also dump the raw symbol table (RTTI class names, vftables, etc.)
        PrintWriter syms = new PrintWriter(new BufferedWriter(new FileWriter(outDir + "/jc2_symbols.txt")));
        SymbolTable st = currentProgram.getSymbolTable();
        int scount = 0;
        for (Symbol s : st.getAllSymbols(true)) {
            syms.println(String.format("%s\t%s\t%s", s.getAddress(), s.getSymbolType(), s.getName(true)));
            scount++;
        }
        syms.close();
        println("wrote " + scount + " symbols to jc2_symbols.txt");

        // 2) full decompilation
        DecompInterface di = new DecompInterface();
        di.openProgram(currentProgram);
        PrintWriter dec = new PrintWriter(new BufferedWriter(new FileWriter(outDir + "/jc2_all_functions_decomp.txt")));
        int done = 0, ok = 0;
        for (Function f : fm.getFunctions(true)) {
            if (monitor.isCancelled()) break;
            DecompileResults r = di.decompileFunction(f, 60, monitor);
            dec.println("// ==== " + f.getEntryPoint() + "  " + f.getName(true) + " ====");
            if (r != null && r.decompileCompleted() && r.getDecompiledFunction() != null) {
                dec.println(r.getDecompiledFunction().getC());
                ok++;
            } else {
                dec.println("// <decompile failed>");
            }
            done++;
            if (done % 500 == 0) println("decompiled " + done + "/" + fcount + " (ok=" + ok + ")");
        }
        dec.close();
        di.dispose();
        println("DONE: decompiled " + ok + "/" + done + " functions");
    }
}
