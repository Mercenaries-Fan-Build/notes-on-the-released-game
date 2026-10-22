// Exports every non-external function of the program (thunks included) as JSON Lines: its name,
// memory block, size, thunk target, callers, call list and decompiled C.
//
// Args: <imageId> <expectedSha256> <outFile> <ordinalTable> <imports|->
//   <imageId>         the image's id (tools/wad_simulator/crates/mercs2_exemap/data/images.tsv),
//                     written into the image record.
//   <expectedSha256>  the sha256 the program's executable must have
//                     (Program.getExecutableSHA256); any other value stops the script before
//                     anything is written.
//   <outFile>         the JSON Lines file to write. The script stops when it already exists. The
//                     lines are written to <outFile>.partial, which is renamed to <outFile> only
//                     after the end record is written; a run that stops leaves no <outFile>.
//   <ordinalTable> <imports>  as FnMnemonicSig.java's; they feed the call list (CallList.java).
//
// Lines (each a JSON object, written with Ghidra's gson):
//   1. {"kind":"image","image_id","program","program_sha256","ghidra_version","language",
//      "compiler_spec","functions":N}
//   2. one per function in entry-address order:
//      {"kind":"function","va":"0x%08x","name","name_source" (the symbol's SourceType: DEFAULT,
//      ANALYSIS, IMPORTED, USER_DEFINED, ...),"block" (memory block of the entry),"size" (body
//      addresses),"thunk":bool,"thunk_target","callers","callees","decomp","decomp_error"}
//      thunk_target  null for a function that is not a thunk; for a thunk, the function it thunks
//                    (Function.getThunkedFunction(false)): "0x%08x" of its entry when it is in
//                    the image, "ext:<library>!<name>" (named as in the call list) when it is an
//                    external function in a named library, and "0x%08x" of the external
//                    location's address when it is in Ghidra's "<EXTERNAL>" library (a jump to an
//                    absolute address outside the image, "EXT_FUN_<addr>").
//      callers       every call reference to the entry (ReferenceManager.getReferencesTo, no cap),
//                    ordered by site: {"site":"0x%08x","function":"0x%08x" of the function
//                    containing the site, or null when no function contains it}.
//      callees       the call list of the body's instructions in address order, exactly as
//                    FnMnemonicSig.java writes it (CallList.addCallees): "0x…", "ext:<lib>!<name>",
//                    "*0x…", "*stack:<signed hex>", "?", "sys:<N>".
//      decomp        the decompiled C, or null when the decompile failed; decomp_error is then the
//                    decompiler's message (or the exception) and null otherwise.
//   3. {"kind":"end","functions":N,"decompiled":<count with C>,"failed":<count without>}
//
// Functions are decompiled in parallel by Ghidra's ghidra.app.decompiler.parallel API
// (ParallelDecompiler, DecompilerCallback) and written in entry-address order. The number of
// decompiler threads is Ghidra's own cpu.core.override Java system property
// (SystemUtilities.getDefaultThreadPoolSize, the size of the "Parallel Decompiler" thread pool).
// It is required: the script stops when it is unset, empty, not an integer, or below 1. With
// analyzeHeadless, pass it as GHIDRA_HEADLESS_JAVA_OPTIONS="-Dcpu.core.override=<threads>".
// scripts/ghidra_export_functions.sh runs this script per image id.
//
// @category Mercs2
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonNull;
import com.google.gson.JsonObject;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.decompiler.parallel.DecompilerCallback;
import ghidra.app.decompiler.parallel.ParallelDecompiler;
import ghidra.app.script.GhidraScript;
import ghidra.framework.Application;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Program;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceIterator;
import ghidra.util.SystemUtilities;
import ghidra.util.task.TaskMonitor;

import java.io.BufferedWriter;
import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

public class ExportFunctions extends GhidraScript {
    private static final String USAGE =
        "<imageId> <expectedSha256> <outFile> <ordinalTable> <imports|->";
    private static final String THREADS_PROPERTY = "cpu.core.override";
    private static final int TIMEOUT_SECS = 60;

    private final Gson gson = new GsonBuilder().serializeNulls().disableHtmlEscaping().create();
    private CallList callList;
    private BufferedWriter out;
    private int decompiled = 0, failed = 0;

    // Script argument <index>; the script stops with the usage line when it is absent.
    private String requiredArg(int index) {
        String[] args = getScriptArgs();
        if (args.length <= index) {
            throw new IllegalArgumentException("missing script argument " + (index + 1)
                + "; usage: " + getClass().getSimpleName() + ".java " + USAGE);
        }
        return args[index];
    }

    // Decompiler thread count from the cpu.core.override system property. Stops the script when
    // the property is unset, empty, not an integer, or below 1, and when Ghidra's thread pool size
    // (SystemUtilities.getDefaultThreadPoolSize) is not that value.
    private int requiredThreads() {
        String v = System.getProperty(THREADS_PROPERTY);
        if (v == null || v.trim().isEmpty()) {
            throw new IllegalArgumentException("Java system property " + THREADS_PROPERTY
                + " (decompiler thread count) is not set; pass -D" + THREADS_PROPERTY
                + "=<threads>, e.g. GHIDRA_HEADLESS_JAVA_OPTIONS=\"-D" + THREADS_PROPERTY
                + "=<threads>\" for analyzeHeadless");
        }
        int n;
        try {
            n = Integer.parseInt(v.trim());
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Java system property " + THREADS_PROPERTY + "='"
                + v + "' is not an integer");
        }
        if (n < 1) {
            throw new IllegalArgumentException("Java system property " + THREADS_PROPERTY + "="
                + n + " is below 1");
        }
        int pool = SystemUtilities.getDefaultThreadPoolSize();
        if (pool != n) {
            throw new IllegalStateException("Ghidra's thread pool size is " + pool + ", not "
                + THREADS_PROPERTY + "=" + n);
        }
        return n;
    }

    private static String hex8(Address a) {
        return String.format("0x%08x", a.getOffset());
    }

    // The decompile of one function: the C text, or the reason there is none.
    private static final class Outcome {
        final Function f;
        final String c;
        final String error;

        Outcome(Function f, String c, String error) {
            this.f = f;
            this.c = c;
            this.error = error;
        }
    }

    // Decompiles one function on a pooled DecompInterface. The pool's decompilers are created
    // with no configuration (DecompileConfigurer is a no-op), as new DecompInterface() +
    // openProgram. Tracks the peak number of decompiles in flight.
    private static final class Callback extends DecompilerCallback<Outcome> {
        private final AtomicInteger inFlight = new AtomicInteger();
        private final AtomicInteger peak = new AtomicInteger();

        Callback(Program program) {
            super(program, decompiler -> { });
            setTimeout(TIMEOUT_SECS);
        }

        @Override
        public Outcome process(Function f, TaskMonitor monitor) throws Exception {
            peak.accumulateAndGet(inFlight.incrementAndGet(), Math::max);
            try {
                return super.process(f, monitor);
            } catch (Exception e) {
                return new Outcome(f, null, "decompile threw " + e);
            } finally {
                inFlight.decrementAndGet();
            }
        }

        @Override
        public Outcome process(DecompileResults res, TaskMonitor monitor) {
            Function f = res.getFunction();
            try {
                if (!res.decompileCompleted()) {
                    String m = res.getErrorMessage();
                    return new Outcome(f, null, m == null || m.trim().isEmpty()
                        ? "the decompile did not complete and the decompiler gave no message" : m.trim());
                }
                return new Outcome(f, res.getDecompiledFunction().getC(), null);
            } catch (Exception e) {
                return new Outcome(f, null, "reading the decompile result threw " + e);
            }
        }
    }

    // The function record of o.f. Stops the script on an entry outside memory or outside every
    // memory block, a thunk with no thunked function, a call reference from outside memory, and
    // every case the call list stops on.
    private JsonObject record(Outcome o) throws Exception {
        Function f = o.f;
        Address entry = f.getEntryPoint();
        if (!entry.isMemoryAddress()) {
            throw new IllegalStateException("function " + f.getName(true) + " has its entry " + entry
                + " outside memory");
        }
        MemoryBlock block = currentProgram.getMemory().getBlock(entry);
        if (block == null) {
            throw new IllegalStateException("function " + f.getName(true) + " at " + entry
                + " is in no memory block");
        }
        JsonObject r = new JsonObject();
        r.addProperty("kind", "function");
        r.addProperty("va", hex8(entry));
        r.addProperty("name", f.getName());
        r.addProperty("name_source", f.getSymbol().getSource().toString());
        r.addProperty("block", block.getName());
        r.addProperty("size", f.getBody().getNumAddresses());
        r.addProperty("thunk", f.isThunk());
        if (f.isThunk()) {
            r.addProperty("thunk_target", callList.thunkTarget(f));
        } else {
            r.add("thunk_target", JsonNull.INSTANCE);
        }
        List<Reference> calls = new ArrayList<>();
        ReferenceIterator refs = currentProgram.getReferenceManager().getReferencesTo(entry);
        while (refs.hasNext()) {
            Reference ref = refs.next();
            if (!ref.getReferenceType().isCall()) continue;
            if (!ref.getFromAddress().isMemoryAddress()) {
                throw new IllegalStateException("call reference to " + f.getName(true) + " at " + entry
                    + " comes from " + ref.getFromAddress() + ", outside memory");
            }
            calls.add(ref);
        }
        calls.sort((a, b) -> a.getFromAddress().compareTo(b.getFromAddress()));
        JsonArray callers = new JsonArray();
        for (Reference ref : calls) {
            JsonObject c = new JsonObject();
            c.addProperty("site", hex8(ref.getFromAddress()));
            Function cf = currentProgram.getFunctionManager().getFunctionContaining(ref.getFromAddress());
            if (cf == null) {
                c.add("function", JsonNull.INSTANCE);
            } else {
                c.addProperty("function", hex8(cf.getEntryPoint()));
            }
            callers.add(c);
        }
        r.add("callers", callers);
        List<String> list = new ArrayList<>();
        for (Instruction m : currentProgram.getListing().getInstructions(f.getBody(), true)) {
            callList.addCallees(m, f, list);
        }
        JsonArray callees = new JsonArray();
        for (String s : list) callees.add(s);
        r.add("callees", callees);
        if (o.c != null) {
            r.addProperty("decomp", o.c);
            r.add("decomp_error", JsonNull.INSTANCE);
        } else {
            r.add("decomp", JsonNull.INSTANCE);
            r.addProperty("decomp_error", o.error);
        }
        return r;
    }

    // Writes each Outcome in the order of the function list, holding out-of-order outcomes until
    // every earlier function has been written. The first exception while writing is kept, the
    // monitor is cancelled, and every later outcome is dropped; run() rethrows it.
    private final class OrderedWriter {
        private final List<Function> order;
        private final Map<Address, Outcome> pending = new HashMap<>();
        private int next = 0;
        private Exception failure = null;

        OrderedWriter(List<Function> order) {
            this.order = order;
        }

        synchronized void accept(Outcome o) {
            if (failure != null) return;
            try {
                if (pending.put(o.f.getEntryPoint(), o) != null) {
                    throw new IllegalStateException("function " + o.f.getName(true) + " @"
                        + o.f.getEntryPoint() + " was decompiled twice");
                }
                while (next < order.size() && pending.containsKey(order.get(next).getEntryPoint())) {
                    Outcome w = pending.remove(order.get(next).getEntryPoint());
                    out.write(gson.toJson(record(w)));
                    out.write('\n');
                    if (w.c != null) decompiled++; else failed++;
                    if (++next % 2000 == 0) println("written " + next + "/" + order.size());
                }
            } catch (Exception e) {
                failure = e;
                monitor.cancel();
            }
        }

        synchronized int written() {
            return next;
        }

        synchronized int held() {
            return pending.size();
        }

        synchronized Exception failure() {
            return failure;
        }
    }

    @Override
    public void run() throws Exception {
        String imageId = requiredArg(0);
        String expectedSha = requiredArg(1);
        File outFile = new File(requiredArg(2));
        String ordinalTable = requiredArg(3);
        String imports = requiredArg(4);
        if (imageId.isEmpty()) {
            throw new IllegalArgumentException("<imageId> is empty");
        }
        if (!expectedSha.matches("[0-9a-f]{64}")) {
            throw new IllegalArgumentException("<expectedSha256> '" + expectedSha
                + "' is not 64 lowercase hex digits");
        }
        String sha = currentProgram.getExecutableSHA256();
        if (!expectedSha.equals(sha)) {
            throw new IllegalStateException(currentProgram.getName() + " has executable sha256 "
                + sha + ", not " + expectedSha + " (image " + imageId + ")");
        }
        if (outFile.exists()) {
            throw new IllegalStateException(outFile + " already exists; remove it to export again");
        }
        int threads = requiredThreads();
        callList = new CallList(this, ordinalTable, imports);

        FunctionManager fm = currentProgram.getFunctionManager();
        List<Function> order = new ArrayList<>();
        for (Function f : fm.getFunctions(true)) {
            if (f.isExternal()) {
                throw new IllegalStateException("FunctionManager.getFunctions returned external function "
                    + f.getName(true));
            }
            order.add(f);
        }
        int externals = 0;
        for (Iterator<Function> it = fm.getExternalFunctions(); it.hasNext(); it.next()) externals++;
        if (fm.getFunctionCount() - externals != order.size()) {
            throw new IllegalStateException("the program has " + fm.getFunctionCount()
                + " functions of which " + externals + " are external, but " + order.size()
                + " non-external functions were listed");
        }
        int total = order.size();

        Path partial = new File(outFile.getPath() + ".partial").toPath();
        Files.deleteIfExists(partial);
        File parent = outFile.getAbsoluteFile().getParentFile();
        if (!parent.isDirectory()) {
            throw new IllegalStateException("output directory " + parent + " does not exist");
        }
        out = Files.newBufferedWriter(partial, StandardCharsets.UTF_8);
        JsonObject image = new JsonObject();
        image.addProperty("kind", "image");
        image.addProperty("image_id", imageId);
        image.addProperty("program", currentProgram.getName());
        image.addProperty("program_sha256", sha);
        image.addProperty("ghidra_version", Application.getApplicationVersion());
        image.addProperty("language", currentProgram.getLanguageID().getIdAsString());
        image.addProperty("compiler_spec", currentProgram.getCompilerSpec().getCompilerSpecID().getIdAsString());
        image.addProperty("functions", total);
        out.write(gson.toJson(image));
        out.write('\n');

        OrderedWriter writer = new OrderedWriter(order);
        Callback callback = new Callback(currentProgram);
        println("decompiling " + total + " functions (" + externals + " external functions not exported) on "
            + threads + " threads (" + THREADS_PROPERTY + "=" + threads + ")");
        long t0 = System.nanoTime();
        try {
            ParallelDecompiler.decompileFunctions(callback, currentProgram, order.iterator(),
                writer::accept, monitor);
        } catch (Exception e) {
            if (writer.failure() == null) throw e;
        } finally {
            callback.dispose();
        }
        long seconds = (System.nanoTime() - t0) / 1_000_000_000L;
        if (writer.failure() != null) {
            out.close();
            throw new IllegalStateException("exporting " + currentProgram.getName() + " stopped after "
                + writer.written() + " of " + total + " functions: " + writer.failure().getMessage(),
                writer.failure());
        }
        if (writer.written() != total) {
            out.close();
            throw new IllegalStateException("wrote " + writer.written() + " of " + total
                + " functions to " + partial + " (" + writer.held()
                + " decompiled out of order and held); the export is incomplete");
        }
        if (callback.peak.get() > threads) {
            out.close();
            throw new IllegalStateException(callback.peak.get() + " decompiles ran at once, more than "
                + THREADS_PROPERTY + "=" + threads);
        }
        if (decompiled + failed != total) {
            out.close();
            throw new IllegalStateException(decompiled + " decompiled + " + failed + " failed is not "
                + total + " functions");
        }
        JsonObject end = new JsonObject();
        end.addProperty("kind", "end");
        end.addProperty("functions", total);
        end.addProperty("decompiled", decompiled);
        end.addProperty("failed", failed);
        out.write(gson.toJson(end));
        out.write('\n');
        out.close();
        Files.move(partial, outFile.toPath(), StandardCopyOption.ATOMIC_MOVE);
        println("peak decompiles in flight: " + callback.peak.get() + " of " + threads + " threads");
        println("ExportFunctions " + imageId + ": " + total + " functions, " + decompiled + " decompiled, "
            + failed + " failed, decompile+write wall time " + seconds + " s -> " + outFile);
    }
}
