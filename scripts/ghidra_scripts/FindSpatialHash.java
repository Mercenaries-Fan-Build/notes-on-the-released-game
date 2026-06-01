// Locate spatial-hash / asset-registration code by string xrefs + program layout.
// VA-independent (works on any Mercs2 build). Native Ghidra Java script.
// Writes output/_ghidra/<progname>_findings.txt
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Reference;

import java.io.File;
import java.io.PrintWriter;
import java.util.Iterator;
import java.util.TreeMap;
import java.util.TreeSet;

public class FindSpatialHash extends GhidraScript {

    private static final String OUT_DIR =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra";

    private static final String[] KEYWORDS = {
        "spatial", "spatialhash", "sceneobject", "scene object", "cell",
        "quadtree", "grid", "bucket", "registerasset", "assetregist",
        "assetmanager", "hibernat", "transform", "road", "intersection",
        "ecs", "component"
    };

    private PrintWriter fp;
    private void w(String s) { fp.println(s); }

    @Override
    public void run() throws Exception {
        new File(OUT_DIR).mkdirs();
        String name = currentProgram.getName().replace(".", "_");
        File out = new File(OUT_DIR, name + "_findings.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            w("# " + currentProgram.getName());
            w("image_base=" + currentProgram.getImageBase());
            w("min=" + currentProgram.getMinAddress() + " max=" + currentProgram.getMaxAddress());
            w("");
            w("## Memory blocks");
            for (MemoryBlock b : currentProgram.getMemory().getBlocks()) {
                w(String.format("  %-10s %s - %s  (%d bytes) x=%s w=%s",
                    b.getName(), b.getStart(), b.getEnd(), b.getSize(),
                    b.isExecute(), b.isWrite()));
            }
            w("");
            w("## String hits + referencing functions");

            FunctionManager fm = currentProgram.getFunctionManager();
            TreeMap<String, String> seenFns = new TreeMap<>();
            Iterator<Data> it = currentProgram.getListing().getDefinedData(true);
            int count = 0;
            while (it.hasNext() && count < 6000) {
                Data d = it.next();
                Object val;
                try { val = d.getValue(); } catch (Exception e) { continue; }
                if (val == null) continue;
                String s = val.toString();
                if (s.length() < 4 || s.length() > 200) continue;
                String low = s.toLowerCase();
                boolean hit = false;
                for (String k : KEYWORDS) { if (low.contains(k)) { hit = true; break; } }
                if (!hit) continue;
                count++;
                Reference[] refs = getReferencesTo(d.getAddress());
                TreeSet<String> fns = new TreeSet<>();
                for (Reference r : refs) {
                    Function f = fm.getFunctionContaining(r.getFromAddress());
                    if (f != null) fns.add(f.getEntryPoint().toString() + " " + f.getName());
                }
                if (!fns.isEmpty()) {
                    String disp = s.length() > 80 ? s.substring(0, 80) : s;
                    w("  \"" + disp + "\" @ " + d.getAddress());
                    for (String ef : fns) {
                        w("      <- " + ef);
                        int sp = ef.indexOf(' ');
                        seenFns.put(ef.substring(0, sp), ef.substring(sp + 1));
                    }
                }
            }
            w("");
            w("## Distinct referencing functions: " + seenFns.size());
        } finally {
            fp.close();
        }
        println("wrote " + out.getAbsolutePath());
    }
}
