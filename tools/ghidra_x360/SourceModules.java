// Tag functions with their source file, from referenced *.cpp/*.h assert strings,
// and report the module -> function-count distribution (an architectural map).
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.ReferenceManager;
import java.util.*;
import java.util.regex.*;

public class SourceModules extends GhidraScript {
    public void run() throws Exception {
        Pattern src = Pattern.compile(".*[\\\\/]([A-Za-z0-9_]+\\.(?:cpp|c|h|inl))(?:\\(\\d+\\))?$",
                Pattern.CASE_INSENSITIVE);
        Listing listing = currentProgram.getListing();
        ReferenceManager rm = currentProgram.getReferenceManager();
        DataIterator di = listing.getDefinedData(true);
        Map<String, Integer> moduleCount = new TreeMap<>();
        Set<Function> seen = new HashSet<>();
        int tagged = 0;
        while (di.hasNext()) {
            Data d = di.next();
            if (!d.hasStringValue()) continue;
            Object v = d.getValue(); if (v == null) continue;
            Matcher m = src.matcher(v.toString().trim());
            if (!m.matches()) continue;
            String base = m.group(1);
            var ri = rm.getReferencesTo(d.getAddress());
            while (ri.hasNext()) {
                Function f = getFunctionContaining(ri.next().getFromAddress());
                if (f == null) continue;
                moduleCount.merge(base, 1, Integer::sum);
                if (seen.add(f)) {
                    String pc = f.getComment();
                    if (pc == null || !pc.contains("source:")) {
                        setPlateComment(f.getEntryPoint(), "source: " + base
                                + (pc != null ? "\n" + pc : ""));
                        tagged++;
                    }
                }
            }
        }
        println("SourceModules: tagged " + tagged + " functions across " + moduleCount.size() + " source files");
        for (Map.Entry<String, Integer> e : moduleCount.entrySet())
            println("  MODCOUNT " + e.getValue() + "  " + e.getKey());
    }
}
