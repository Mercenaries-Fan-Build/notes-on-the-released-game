// Apply the community Ghidra FID databases (tools/fidb/*.fidb) to the PC image and export
// every FID match to output/_ghidra/fid_matches.csv (addr,fid_name,score,library,version).
// Byte-signature identification (FLIRT/FID): a match names a statically-linked library function
// authoritatively. NOTE the shipped repo is Linux/GCC (glibc/gcc/openssl/qt/SDL); a MSVC
// (MSVCR80) game will mostly NOT match — the empty/tiny result IS the finding, and confirms an
// MSVC-runtime fidb (or a self-built one) is what's needed.
//
// Headless: JAVA_HOME=tools/jdk21/jdk-21.0.11+10; analyzeHeadless output/_ghidra/proj_unpacked \
//   m2_unpacked -process mercs2_unpacked.exe -noanalysis -scriptPath scripts/ghidra_scripts \
//   -postScript FidApplyExport.java
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.feature.fid.db.FidFileManager;
import ghidra.feature.fid.db.FidQueryService;
import ghidra.feature.fid.db.LibraryRecord;
import ghidra.feature.fid.service.FidMatch;
import ghidra.feature.fid.service.FidSearchResult;
import ghidra.feature.fid.service.FidService;

import java.io.File;
import java.io.PrintWriter;
import java.util.List;

public class FidApplyExport extends GhidraScript {
    private static final String ROOT = "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\";
    private static final String OUT = ROOT + "output\\_ghidra\\fid_matches.csv";

    private String csv(String s) {
        if (s == null) return "";
        return (s.indexOf(',') >= 0 || s.indexOf('"') >= 0)
            ? "\"" + s.replace("\"", "\"\"") + "\"" : s;
    }

    @Override
    public void run() throws Exception {
        FidFileManager ffm = FidFileManager.getInstance();
        File dir = new File(ROOT + "tools\\fidb");
        File[] all = dir.listFiles();
        int attached = 0;
        if (all != null) {
            for (File f : all) {
                if (f.getName().toLowerCase().endsWith(".fidb")) {
                    try { ffm.addUserFidFile(f); attached++; }
                    catch (Exception e) { println("skip " + f.getName() + ": " + e.getMessage()); }
                }
            }
        }
        ffm.load();
        boolean canQuery = ffm.canQuery(currentProgram.getLanguage());
        println("FID: attached " + attached + " db(s); program lang=" + currentProgram.getLanguageID()
            + "; canQuery=" + canQuery);

        PrintWriter pw = new PrintWriter(new File(OUT), "UTF-8");
        pw.println("addr,fid_name,score,library,version");
        if (!canQuery) {
            println("FID: no attached db matches the program language -> 0 matches.");
            pw.close();
            return;
        }
        FidService service = new FidService();
        FidQueryService q = ffm.openFidQueryService(currentProgram.getLanguage(), false);
        List<FidSearchResult> results =
            service.processProgram(currentProgram, q, service.getDefaultScoreThreshold(), monitor);
        int n = 0;
        for (FidSearchResult r : results) {
            if (r.matches == null || r.matches.isEmpty()) continue;
            FidMatch best = null;
            float bs = -1f;
            for (FidMatch m : r.matches) {
                if (m.getOverallScore() > bs) { bs = m.getOverallScore(); best = m; }
            }
            if (best == null) continue;
            String name = best.getFunctionRecord().getName();
            LibraryRecord lib = best.getLibraryRecord();
            String fam = lib != null ? lib.getLibraryFamilyName() : "";
            String ver = lib != null ? lib.getLibraryVersion() : "";
            long a = r.function.getEntryPoint().getOffset();
            pw.println(String.format("0x%08x,%s,%.1f,%s,%s", a, csv(name), bs, csv(fam), csv(ver)));
            n++;
        }
        pw.close();
        q.close();
        println("FID: " + n + " functions matched -> " + OUT);
    }
}
