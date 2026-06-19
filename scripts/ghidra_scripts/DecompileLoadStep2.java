// Re-target: correctly capture the 16-byte-record allocator functions the first pass mis-bounded.
// The previous scan-back-for-(55 8B EC) found the WRONG function for 0x00414B0B (FUN_00414850 ends
// at 0x414A94, before the target — the real function uses a non-(55 8B EC) prologue). This resolver
// instead walks FORWARD from the previous function's end, creating functions and checking that the
// one it makes actually CONTAINS the target address.
//
// Targets (16-byte DCE0 allocators from the poolguard v12 timeline):
//   0x00414B0B  per-entity 16-byte record alloc (prime suspect for the 16-byte victim class)
//   0x004781E7  16-byte alloc
//   0x0085BFB0  16-byte alloc
//   0x0074D74C  16-byte alloc
// Writes output/_ghidra/loadstep2_decomp.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.mem.Memory;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;

public class DecompileLoadStep2 extends GhidraScript {

    private static final long[] TARGETS = {
        0x00414B0BL, 0x004781E7L, 0x0085BFB0L, 0x0074D74CL,
    };
    private static final String[] LABELS = {
        "call @0x00414B0B  per-entity 16-byte record alloc (prime suspect)",
        "call @0x004781E7  16-byte alloc",
        "call @0x0085BFB0  16-byte alloc",
        "call @0x0074D74C  16-byte alloc",
    };
    private static final String OUT_DIR =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra";

    private Memory mem;
    private PrintWriter fp;
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }

    // Resolve the function that CONTAINS va, even when it has an unusual prologue Ghidra hasn't
    // auto-defined. Walk forward from the previous function's end, skipping CC/90 padding.
    private Function resolveFn(long va) throws Exception {
        Address target = addr(va);
        Function f = getFunctionContaining(target);
        if (f != null && f.getBody().contains(target)) return f;

        Function prev = getFunctionBefore(target);
        long start = (prev != null) ? prev.getBody().getMaxAddress().getOffset() + 1 : va - 0x400;
        for (int guard = 0; guard < 16 && start <= va; guard++) {
            try {
                while (start < va) {
                    int b = mem.getByte(addr(start)) & 0xff;
                    if (b == 0xCC || b == 0x90) start++; else break;
                }
            } catch (Exception ex) { break; }
            if (start > va) break;
            disassemble(addr(start));
            Function nf = createFunction(addr(start), null);
            if (nf == null) nf = getFunctionContaining(addr(start));
            if (nf == null) { start++; continue; }
            if (nf.getBody().contains(target)) return nf;
            long nend = nf.getBody().getMaxAddress().getOffset();
            start = (nend > start) ? nend + 1 : start + 1;
        }
        return getFunctionContaining(target);
    }

    @Override
    public void run() throws Exception {
        mem = currentProgram.getMemory();
        new File(OUT_DIR).mkdirs();
        File out = new File(OUT_DIR, "loadstep2_decomp.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
            String bar = new String(new char[78]).replace("\0", "=");
            w("# Mercs2 16-byte-record allocators (over-write hunt, re-targeted resolver)");
            w("# program: " + currentProgram.getName());
            w("");
            for (int i = 0; i < TARGETS.length; i++) {
                w(bar);
                w(String.format("TARGET call-site 0x%08x  %s", TARGETS[i], LABELS[i]));
                Function f = resolveFn(TARGETS[i]);
                if (f == null) { w("  (could not resolve a containing function)"); w(""); continue; }
                boolean contains = f.getBody().contains(addr(TARGETS[i]));
                w("  -> " + f.getName() + " entry=" + f.getEntryPoint()
                    + " size=" + f.getBody().getNumAddresses()
                    + " contains_target=" + contains);
                try {
                    DecompileResults res = decomp.decompileFunction(f, 120, mon);
                    if (res != null && res.decompileCompleted()) w(res.getDecompiledFunction().getC());
                    else w("  DECOMP FAILED");
                } catch (Exception ex) { w("  DECOMP EXC: " + ex); }
                w("");
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
