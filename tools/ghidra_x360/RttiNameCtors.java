// Name class constructors via RTTI: rtti_vtables.txt maps vtable VA -> class.
// A function that references exactly one class vtable (Ghidra resolved the PPC
// lis/addi address load) is that class's constructor/vtable-setter.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.*;
import java.nio.file.*;
import java.util.*;

public class RttiNameCtors extends GhidraScript {
    public void run() throws Exception {
        String fp = "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra_x360\\rtti_vtables.txt";
        ReferenceManager rm = currentProgram.getReferenceManager();
        int labeled = 0;
        // function -> set of classes whose vtable it references
        Map<Function, Set<String>> fnClasses = new HashMap<>();
        for (String line : Files.readAllLines(Paths.get(fp))) {
            String[] p = line.trim().split("\\s+", 2);
            if (p.length < 2) continue;
            Address vt = toAddr(Long.parseLong(p[0], 16));
            String cls = p[1];
            try { createLabel(vt, cls + "__vftable", true); labeled++; } catch (Exception e) { }
            var ri = rm.getReferencesTo(vt);
            while (ri.hasNext()) {
                Function f = getFunctionContaining(ri.next().getFromAddress());
                if (f != null) fnClasses.computeIfAbsent(f, k -> new HashSet<>()).add(cls);
            }
        }
        int named = 0;
        Set<String> used = new HashSet<>();
        for (Map.Entry<Function, Set<String>> e : fnClasses.entrySet()) {
            Function f = e.getKey();
            if (e.getValue().size() != 1) continue;       // skip factories/multi-vtable
            if (!f.getName().startsWith("FUN_")) continue;
            String nm = e.getValue().iterator().next() + "_ctor";
            while (used.contains(nm)) nm = nm + "_";
            try { f.setName(nm, SourceType.USER_DEFINED); used.add(nm); named++; } catch (Exception ex) { }
        }
        println("RttiNameCtors: labeled " + labeled + " vtables, named " + named + " constructors");
    }
}
