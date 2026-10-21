// Export decompiled C for every FUN_* in .text, named per-program so multiple
// builds can be analyzed without clobbering each other's output.
// Args: <outDir>  — writes <outDir>/<programName>_decomp.txt
// (Sibling of DecompileAllFunctions.java, which hardcodes all_functions_decomp.txt.)
//
// Functions are decompiled in parallel by Ghidra's ghidra.app.decompiler.parallel API
// (ParallelDecompiler, DecompilerCallback) and written in entry-address order, so the file is the
// same as a one-at-a-time export. The number of decompiler threads is Ghidra's own
// cpu.core.override Java system property (SystemUtilities.getDefaultThreadPoolSize, the size of
// the "Parallel Decompiler" thread pool). It is required: the script stops when it is unset,
// empty, not an integer, or below 1. With analyzeHeadless, pass it as
// GHIDRA_HEADLESS_JAVA_OPTIONS="-Dcpu.core.override=<threads>".
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.decompiler.parallel.DecompilerCallback;
import ghidra.app.decompiler.parallel.ParallelDecompiler;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.listing.Program;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Reference;
import ghidra.util.SystemUtilities;
import ghidra.util.task.TaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.atomic.AtomicInteger;

public class DecompileAllByName extends GhidraScript {
    private static final String USAGE = "<outDir>";
    private static final String THREADS_PROPERTY = "cpu.core.override";
    private static final int TIMEOUT_SECS = 60;
    private String outDir;

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

    // x87 math helpers (sqrt/abs/…) were falsely marked noreturn, truncating every
    // float-heavy function at its first sqrt call. Clear the flag so the export is
    // correct regardless of whether the fix was persisted to the project DB.
    private static final long[] FALSE_NORETURN = {0x401740L, 0x401750L, 0x4017a0L, 0x401630L};

    private void clearFalseNoReturn() {
        for (long a : FALSE_NORETURN) {
            Function f = getFunctionAt(currentProgram.getAddressFactory()
                .getDefaultAddressSpace().getAddress(a));
            if (f != null && f.hasNoReturn()) {
                f.setNoReturn(false);
                println("cleared noreturn on " + f.getName());
            }
        }
    }

    private PrintWriter fp;

    private String callersOf(Function f) {
        StringBuilder sb = new StringBuilder();
        int n = 0;
        for (Reference r : getReferencesTo(f.getEntryPoint())) {
            if (!r.getReferenceType().isCall()) continue;
            Function c = getFunctionContaining(r.getFromAddress());
            sb.append(String.format("0x%08x%s ", r.getFromAddress().getOffset(),
                c != null ? "(" + c.getName() + ")" : ""));
            if (++n >= 12) { sb.append("..."); break; }
        }
        return sb.toString().trim();
    }

    // The decompile of one function. decompileError: the decompile itself threw (written as
    // "  EXC <e>" with no header). Otherwise the header is written, then bodyError as
    // "  EXC <e>" when reading the result threw, else body (the C text or "  DECOMP FAIL").
    private static final class Outcome {
        final Function f;
        final Exception decompileError;
        final Exception bodyError;
        final String body;

        Outcome(Function f, Exception decompileError, Exception bodyError, String body) {
            this.f = f;
            this.decompileError = decompileError;
            this.bodyError = bodyError;
            this.body = body;
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
                return new Outcome(f, e, null, null);
            } finally {
                inFlight.decrementAndGet();
            }
        }

        @Override
        public Outcome process(DecompileResults res, TaskMonitor monitor) {
            Function f = res.getFunction();
            try {
                String body = res.decompileCompleted()
                    ? res.getDecompiledFunction().getC()
                    : "  DECOMP FAIL";
                return new Outcome(f, null, null, body);
            } catch (Exception e) {
                return new Outcome(f, null, e, null);
            }
        }
    }

    // Writes each Outcome in the order of the function list, holding out-of-order outcomes
    // until every earlier function has been written.
    private final class OrderedWriter {
        private final List<Function> order;
        private final Map<Address, Outcome> pending = new HashMap<>();
        private int next = 0;

        OrderedWriter(List<Function> order) {
            this.order = order;
        }

        synchronized void accept(Outcome o) {
            if (pending.put(o.f.getEntryPoint(), o) != null) {
                throw new IllegalStateException("function " + o.f.getName() + " @"
                    + o.f.getEntryPoint() + " was decompiled twice");
            }
            while (next < order.size() && pending.containsKey(order.get(next).getEntryPoint())) {
                write(pending.remove(order.get(next).getEntryPoint()));
                if (++next % 50 == 0) { println("decompiled " + next + "/" + order.size()); fp.flush(); }
            }
        }

        synchronized int written() {
            return next;
        }

        synchronized int held() {
            return pending.size();
        }

        private void write(Outcome o) {
            Function f = o.f;
            try {
                if (o.decompileError != null) throw o.decompileError;
                fp.println("============================================================");
                fp.println(String.format("==== %s @0x%08x  size=%d  callers=[%s] ====",
                    f.getName(), f.getEntryPoint().getOffset(), f.getBody().getNumAddresses(), callersOf(f)));
                if (o.bodyError != null) throw o.bodyError;
                fp.println(o.body);
            } catch (Exception e) { fp.println("  EXC " + e); }
        }
    }

    @Override
    public void run() throws Exception {
        outDir = requiredArg(0);
        int threads = requiredThreads();
        clearFalseNoReturn();
        String outPath = new File(outDir, currentProgram.getName() + "_decomp.txt").getPath();
        new File(outDir).mkdirs();
        fp = new PrintWriter(new File(outPath), "UTF-8");
        FunctionManager fm = currentProgram.getFunctionManager();

        long lo = Long.MAX_VALUE, hi = 0;
        for (MemoryBlock b : currentProgram.getMemory().getBlocks()) {
            if (b.isExecute()) {
                lo = Math.min(lo, b.getStart().getOffset());
                hi = Math.max(hi, b.getEnd().getOffset());
            }
        }
        TreeMap<Long, Function> work = new TreeMap<>();
        for (Function f : fm.getFunctions(true)) {
            long off = f.getEntryPoint().getOffset();
            if (off >= lo && off <= hi && !f.isThunk()) work.put(off, f);
        }

        fp.println(String.format("# %s ALL export: %d functions", currentProgram.getName(), work.size()));
        int total = work.size();
        List<Function> order = new ArrayList<>(work.values());
        OrderedWriter writer = new OrderedWriter(order);
        Callback callback = new Callback(currentProgram);
        println("decompiling " + total + " functions on " + threads + " threads ("
            + THREADS_PROPERTY + "=" + threads + ")");
        try {
            ParallelDecompiler.decompileFunctions(callback, currentProgram, order.iterator(),
                writer::accept, monitor);
        } finally {
            callback.dispose();
        }
        if (writer.written() != total) {
            fp.close();
            throw new IllegalStateException("wrote " + writer.written() + " of " + total
                + " functions to " + outPath + " (" + writer.held()
                + " decompiled out of order and held); the export is incomplete");
        }
        if (callback.peak.get() > threads) {
            fp.close();
            throw new IllegalStateException(callback.peak.get() + " decompiles ran at once, more than "
                + THREADS_PROPERTY + "=" + threads);
        }
        boolean writeError = fp.checkError();
        fp.close();
        if (writeError) {
            throw new IllegalStateException("writing " + outPath + " failed");
        }
        println("peak decompiles in flight: " + callback.peak.get() + " of " + threads + " threads");
        println("done -> " + outPath + "  (" + total + " functions)");
    }
}
