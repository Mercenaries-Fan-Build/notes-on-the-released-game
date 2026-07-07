// Export function -> class/namespace attribution from Ghidra's RTTI analysis, for the
// mercs2_reassemble evidence layer. Two evidence sources, both RTTI-derived (not guessed):
//   1. namespace  — each function's parent namespace (the C++ class from demangling/RTTI).
//   2. vtable     — every "<Class>::vftable" data symbol is walked as a pointer array; each
//                   pointed-to function is a method of <Class> (names most virtual methods that
//                   are still FUN_ in the decomp text).
// Output CSV: output/_ghidra/func_class_map.csv  => addr,class,name,source
//
// Run headless against the already-analyzed project (no re-analysis):
//   support/analyzeHeadless.bat <proj_loc> m2_unpacked -process mercs2_unpacked.exe \
//       -noanalysis -scriptPath scripts/ghidra_scripts -postScript ExportFuncClass.java
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.mem.Memory;
import ghidra.program.model.symbol.Namespace;
import ghidra.program.model.symbol.Symbol;
import ghidra.program.model.symbol.SymbolTable;

import java.io.File;
import java.io.PrintWriter;

public class ExportFuncClass extends GhidraScript {
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\func_class_map.csv";

    private String csv(String s) {
        return (s.indexOf(',') >= 0 || s.indexOf('"') >= 0)
            ? "\"" + s.replace("\"", "\"\"") + "\"" : s;
    }

    @Override
    public void run() throws Exception {
        PrintWriter pw = new PrintWriter(new File(OUT), "UTF-8");
        pw.println("addr,class,name,source");
        FunctionManager fm = currentProgram.getFunctionManager();
        SymbolTable st = currentProgram.getSymbolTable();
        Memory mem = currentProgram.getMemory();
        int ps = currentProgram.getDefaultPointerSize();
        long imgLo = currentProgram.getMinAddress().getOffset();
        long imgHi = currentProgram.getMaxAddress().getOffset();

        // 1. namespace / class per function (RTTI + demangler)
        int nsN = 0;
        for (Function f : fm.getFunctions(true)) {
            Namespace ns = f.getParentNamespace();
            if (ns == null || ns.isGlobal()) continue;
            String cls = ns.getName(true);
            if (cls.isEmpty() || cls.equals("Global")) continue;
            pw.println(String.format("0x%08x,%s,%s,namespace",
                f.getEntryPoint().getOffset(), csv(cls), csv(f.getName())));
            nsN++;
        }

        // 2. vtable membership — every "<Class>::vftable" symbol, walked as a fn-pointer array
        int vtSyms = 0, vtFns = 0;
        for (Symbol s : st.getAllSymbols(false)) {
            String nm = s.getName(true);
            int idx = nm.indexOf("::vftable");
            if (idx < 0) continue;
            String cls = nm.substring(0, idx);
            if (cls.isEmpty()) continue;
            vtSyms++;
            Address base = s.getAddress();
            for (int i = 0; i < 2048; i++) {
                Address slot;
                try { slot = base.add((long) i * ps); } catch (Exception e) { break; }
                // stop if a *different* named symbol begins here (next vtable/table) for i>0
                if (i > 0) {
                    Symbol ps2 = st.getPrimarySymbol(slot);
                    if (ps2 != null && !ps2.getName(true).equals(nm)) break;
                }
                long p;
                try {
                    p = (ps == 8) ? mem.getLong(slot) : (mem.getInt(slot) & 0xffffffffL);
                } catch (Exception e) { break; }
                if (p < imgLo || p > imgHi) { if (i == 0) continue; else break; }
                Function tf = fm.getFunctionAt(toAddr(p));
                if (tf == null) {
                    if (i == 0) continue; // some vtables lead with an RTTI/meta slot
                    else break;
                }
                pw.println(String.format("0x%08x,%s,%s,vtable",
                    tf.getEntryPoint().getOffset(), csv(cls), csv(tf.getName())));
                vtFns++;
            }
        }
        pw.close();
        println("ExportFuncClass: " + nsN + " namespace rows, " + vtSyms + " vtables -> "
            + vtFns + " vtable-method rows. Wrote " + OUT);
    }
}
