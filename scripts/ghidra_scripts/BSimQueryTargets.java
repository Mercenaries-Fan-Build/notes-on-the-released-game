// BSim-query a list of functions (current program) against a committed BSim DB, print top matches.
// Args: <bsimURL> <VA> <VA> ...   (run on the NAMED WildStarXenon program; DB holds Mercs2 sigs)
// @category BSim
import ghidra.app.script.GhidraScript;
import ghidra.features.bsim.query.*;
import ghidra.features.bsim.query.description.*;
import ghidra.features.bsim.query.protocol.*;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;

import java.net.URL;
import java.util.Iterator;

public class BSimQueryTargets extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String dburl = args[0];
        URL url = BSimClientFactory.deriveBSimURL(dburl);
        try (FunctionDatabase db = BSimClientFactory.buildClient(url, false)) {
            if (!db.initialize()) { println("DB init fail: " + db.getLastError().message); return; }
            for (int i = 1; i < args.length; i++) {
                long va = Long.decode(args[i]);
                Address a = toAddr(va);
                Function f = getFunctionAt(a);
                println("========================================================");
                if (f == null) { println("NO FUNCTION @ " + args[i]); continue; }
                println("QUERY " + f.getName() + " @" + args[i]);
                GenSignatures gensig = new GenSignatures(false);
                try {
                    gensig.setVectorFactory(db.getLSHVectorFactory());
                    gensig.openProgram(currentProgram, null, null, null, null, null);
                    gensig.scanFunction(f);
                    QueryNearest q = new QueryNearest();
                    q.manage = gensig.getDescriptionManager();
                    q.max = 6;
                    q.thresh = 0.0;         // accept all — we rank manually
                    q.signifthresh = 0.0;
                    ResponseNearest resp = q.execute(db);
                    if (resp == null) { println("  query err: " + db.getLastError().message); continue; }
                    for (SimilarityResult sr : resp.result) {
                        Iterator<SimilarityNote> it = sr.iterator();
                        while (it.hasNext()) {
                            SimilarityNote n = it.next();
                            FunctionDescription fd = n.getFunctionDescription();
                            println(String.format("   -> Mercs2 %-22s  sim=%.4f  signif=%.2f",
                                fd.getFunctionName(), n.getSimilarity(), n.getSignificance()));
                        }
                    }
                } finally { gensig.dispose(); }
            }
        }
    }
}
