// Create a function at every SecuROM-moved code body that SpliceMap.java found without one.
//
// SpliceMap.java lists every .text transfer into the SecuROM blocks. A site whose outcome is
// "moved" reaches code that ends only in returns, imports or the code block: a game function body
// that SecuROM moved out of .text. Most are entered by `JMP dword ptr [slot]`, so Ghidra's
// analysis never makes them functions and they have no signature to match. This script creates a
// function (Ghidra's CreateFunction, default name) at the target of every "moved" site where none
// starts, and writes one TSV row per such target. The program must be opened writable; the
// headless run saves it.
//
// Args: <splicesTsv> <outTsv>
//   splicesTsv  SpliceMap.java output for this program
//   outTsv      TSV written (must not exist): target, site, result (created | failed), body_size
// The script stops when the splices file lacks a column it needs, when a target is not a valid
// address, or when any creation fails (after writing every row). The last line printed is
// "CreateMovedFunctions: <created> created, <existing> already functions in <program>".
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.PrintWriter;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class CreateMovedFunctions extends GhidraScript {
    private static final String USAGE = "<splicesTsv> <outTsv>";

    private String requiredArg(int index) {
        String[] args = getScriptArgs();
        if (args.length <= index) {
            throw new IllegalArgumentException("missing script argument " + (index + 1)
                + "; usage: " + getClass().getSimpleName() + ".java " + USAGE);
        }
        return args[index];
    }

    @Override
    public void run() throws Exception {
        File in = new File(requiredArg(0));
        File out = new File(requiredArg(1));
        if (out.exists()) {
            throw new IllegalArgumentException("output already exists: " + out);
        }
        Map<String, String> targets = new LinkedHashMap<>();
        try (BufferedReader br = new BufferedReader(new FileReader(in))) {
            List<String> head = Arrays.asList(br.readLine().split("\t", -1));
            int iSite = head.indexOf("site"), iTarget = head.indexOf("target"), iOutcome = head.indexOf("outcome");
            if (iSite < 0 || iTarget < 0 || iOutcome < 0) {
                throw new IllegalArgumentException(in + " lacks a site, target or outcome column");
            }
            String line;
            while ((line = br.readLine()) != null) {
                String[] f = line.split("\t", -1);
                if ("moved".equals(f[iOutcome])) targets.putIfAbsent(f[iTarget], f[iSite]);
            }
        }
        int created = 0, existing = 0, failed = 0;
        PrintWriter pw = new PrintWriter(out, "UTF-8");
        pw.println("target\tsite\tresult\tbody_size");
        for (Map.Entry<String, String> e : targets.entrySet()) {
            Address a = toAddr(e.getKey());
            if (a == null) {
                pw.close();
                throw new IllegalArgumentException("target " + e.getKey() + " is not a valid address");
            }
            if (getFunctionAt(a) != null) {
                existing++;
                continue;
            }
            Function fn = createFunction(a, null);
            if (fn == null) {
                failed++;
                pw.println(e.getKey() + "\t" + e.getValue() + "\tfailed\t-");
            } else {
                created++;
                pw.println(e.getKey() + "\t" + e.getValue() + "\tcreated\t" + fn.getBody().getNumAddresses());
            }
        }
        pw.close();
        if (failed > 0) {
            throw new IllegalStateException(failed + " function creations failed; see " + out);
        }
        println("CreateMovedFunctions: " + created + " created, " + existing + " already functions in "
            + currentProgram.getName());
    }
}
