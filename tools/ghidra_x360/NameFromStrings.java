// Name functions from the Xbox build's own debug strings.
// Heuristic: a `Class::Method`-style string referenced by exactly one function is
// almost always that function's own assert/log identifier -> name the function.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.util.*;
import java.util.regex.*;

public class NameFromStrings extends GhidraScript {
    public void run() throws Exception {
        // Tier 1: Class::Method  ;  Tier 2: a CamelCase function-name-like identifier
        Pattern method = Pattern.compile("[A-Za-z_][A-Za-z0-9_]{2,}(::~?[A-Za-z0-9_]+)+");
        Pattern camel = Pattern.compile("_?[A-Z][a-z0-9]+[A-Z][A-Za-z0-9]{2,}");
        Listing listing = currentProgram.getListing();
        ReferenceManager rm = currentProgram.getReferenceManager();
        DataIterator di = listing.getDefinedData(true);
        int named = 0, seen = 0;
        Set<String> usedNames = new HashSet<>();
        while (di.hasNext()) {
            Data d = di.next();
            if (!d.hasStringValue()) continue;
            Object v = d.getValue();
            if (v == null) continue;
            String s = v.toString().trim();
            if (!(method.matcher(s).matches() || camel.matcher(s).matches())) continue;
            seen++;
            Set<Function> refFns = new HashSet<>();
            var ri = rm.getReferencesTo(d.getAddress());
            while (ri.hasNext()) {
                Function f = getFunctionContaining(ri.next().getFromAddress());
                if (f != null) refFns.add(f);
            }
            if (refFns.size() == 1) {
                Function f = refFns.iterator().next();
                if (f.getName().startsWith("FUN_")) {
                    String nm = s.replaceAll("[^A-Za-z0-9_]", "_");
                    while (usedNames.contains(nm)) nm = nm + "_";
                    try { f.setName(nm, SourceType.USER_DEFINED); usedNames.add(nm); named++; }
                    catch (Exception e) { }
                }
            }
        }
        println("NameFromStrings: " + seen + " Class::Method strings, named " + named + " functions");
    }
}
