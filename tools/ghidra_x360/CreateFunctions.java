// Script: create a function at every start address listed in <startsPath>, as a preScript (before
// auto-analysis, seeding an import) or as a postScript on a saved program opened writable (seeding
// functions analysis did not create; the run saves the program).
// Args: <startsPath> <outTsv> <inside>
//   startsPath  one hex VA per line (no 0x prefix), e.g. the .pdata function starts of the image
//               being imported, or an `exemap seeds` list. The list must belong to that image: the
//               builds share no layout.
//   outTsv      TSV written (must not exist), one row per start in list order:
//               address (0x%08x), disassembled (yes when the start had no instruction and this
//               script disassembled it, else no), result (created | existing | failed),
//               body_size (the function's address count; - when failed), detail (the function a
//               created start split, or why a start failed; - otherwise).
//   inside      what a start inside the body of another function means — the list's authority:
//               split   the start is a real function start (e.g. .pdata, the exception table):
//                       create it, splitting that function; the row's detail names it.
//               refuse  the start is a hint (e.g. an RTTI or luaL_Reg target): the start fails,
//                       naming that function, and nothing is created there.
// A start also fails when disassembling it leaves no instruction there, or when Ghidra creates no
// function at it. The script writes every row, then stops when any start failed or a line is not a
// hex VA. Run on a program opened -readOnly, it is a dry run: the rows say what would happen and
// nothing is saved. Each created function is queued for analysis (AutoAnalysisManager
// .functionDefined); on a saved program, run AnalyzeChanges.java after it to analyse them. The last
// line printed is
// "CreateFunctions: <n> starts, disassembled <d>, created <c> (<s> splitting a function), existing <e> functions".
// @category Mercs2
import ghidra.app.plugin.core.analysis.AutoAnalysisManager;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import java.io.File;
import java.io.PrintWriter;
import java.nio.file.*;
import java.util.List;

public class CreateFunctions extends GhidraScript {
    private static final String USAGE = "<startsPath> <outTsv> <split|refuse>";

    // Script argument <index>; the script stops with the usage line when it is absent.
    private String requiredArg(int index) {
        String[] args = getScriptArgs();
        if (args.length <= index) {
            throw new IllegalArgumentException("missing script argument " + (index + 1)
                + "; usage: " + getClass().getSimpleName() + ".java " + USAGE);
        }
        return args[index];
    }

    // What the listing holds at `a` when it holds no instruction there: the middle of an
    // instruction (with its start), defined data (with its type and start), or nothing.
    private String describe(Address a) {
        ghidra.program.model.listing.Listing listing = currentProgram.getListing();
        ghidra.program.model.listing.Instruction in = listing.getInstructionContaining(a);
        if (in != null) return String.format("inside the instruction at 0x%08x", in.getMinAddress().getOffset());
        ghidra.program.model.listing.Data d = listing.getDefinedDataContaining(a);
        if (d != null) return String.format("data %s at 0x%08x", d.getDataType().getName(), d.getMinAddress().getOffset());
        return "undefined";
    }

    public void run() throws Exception {
        String fp = requiredArg(0);
        File out = new File(requiredArg(1));
        if (out.exists()) {
            throw new IllegalArgumentException("output already exists: " + out);
        }
        String inside = requiredArg(2);
        if (!"split".equals(inside) && !"refuse".equals(inside)) {
            throw new IllegalArgumentException("argument 3 is '" + inside + "', not split or refuse; usage: "
                + getClass().getSimpleName() + ".java " + USAGE);
        }
        boolean split = "split".equals(inside);
        AutoAnalysisManager mgr = AutoAnalysisManager.getAnalysisManager(currentProgram);
        List<String> lines = Files.readAllLines(Paths.get(fp));
        int dis = 0, created = 0, splits = 0, existing = 0, failed = 0, n = 0;
        try (PrintWriter w = new PrintWriter(out, "UTF-8")) {
            w.println("address\tdisassembled\tresult\tbody_size\tdetail");
            for (int ln = 0; ln < lines.size(); ln++) {
                String line = lines.get(ln).trim();
                if (line.isEmpty()) continue;
                long va;
                try {
                    va = Long.parseLong(line, 16);
                } catch (NumberFormatException e) {
                    throw new IllegalArgumentException(fp + " line " + (ln + 1) + ": '" + line + "' is not a hex VA");
                }
                Address a = toAddr(va);
                boolean disassembled = false;
                String result, detail = "-", size = "-";
                Function f = getFunctionAt(a);
                Function host = f == null ? getFunctionContaining(a) : null;
                String hostText = host == null ? null
                    : String.format("%s @0x%08x", host.getName(), host.getEntryPoint().getOffset());
                if (f == null && (host == null || split) && getInstructionAt(a) == null) { disassemble(a); dis++; disassembled = true; }
                if (f != null) {
                    result = "existing";
                    existing++;
                } else if (host != null && !split) {
                    result = "failed";
                    detail = "inside " + hostText;
                } else if (getInstructionAt(a) == null) {
                    result = "failed";
                    detail = "no instruction at the start after disassembly: " + describe(a);
                } else {
                    f = createFunction(a, null);
                    if (f != null) {
                        // Function creation reaches the analysis manager only through change events,
                        // which a headless -noanalysis run does not turn into analysis work: queue
                        // the function's analysis directly, for the run's next analysis.
                        mgr.functionDefined(f.getBody());
                        result = "created";
                        created++;
                        if (host != null) { detail = "split " + hostText; splits++; }
                    } else {
                        result = "failed";
                        detail = "Ghidra created no function";
                    }
                }
                if (f != null) size = Long.toString(f.getBody().getNumAddresses());
                if ("failed".equals(result)) failed++;
                w.println(String.format("0x%08x\t%s\t%s\t%s\t%s", va, disassembled ? "yes" : "no", result, size, detail));
                if ((++n % 5000) == 0) println("  ...processed " + n + " (dis=" + dis + " created=" + created + ")");
            }
            if (w.checkError()) throw new IllegalStateException("writing " + out + " failed");
        }
        println("CreateFunctions: " + n + " starts, disassembled " + dis + ", created " + created
            + " (" + splits + " splitting a function), existing " + existing + " functions");
        if (failed > 0) {
            throw new IllegalStateException(failed + " of " + n + " starts failed; see " + out);
        }
    }
}
