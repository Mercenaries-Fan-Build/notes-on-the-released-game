// Decompile the array3-record CONSUMERS (FUN_0067a7fa builds {int,hash,hash} records correctly;
// the overrun is a consumer that walks/copies them with a wrong count). Smoking gun: poolguard2
// faulted at 0x00466B48 dereferencing a record hash (0xF011157A) as a pointer ([hash+0x20]).
//
// Targets (from the dd5b install-pop + the 0x466B48 deref + the 0x4CC064 stacks):
//   0x00466B48  THE deref-hash-as-pointer fault (consumer walking the record array)
//   0x00669787  allocated poolguard2's bad 16-byte block (chunk-parser region)
//   0x004CF5AD  allocated the dd5b victim P (CHDR / world-load region; 0x4CF58B is the known CHDR fix)
//   0x004C1540  world-load loop frame above the entity loader
// Writes output/_ghidra/consumers_decomp.txt.
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

public class DecompileConsumers extends GhidraScript {

    private static final long[] TARGETS = {
        0x00466B48L, 0x00669787L, 0x004CF5ADL, 0x004C1540L,
    };
    private static final String[] LABELS = {
        "deref hash-as-pointer fault [EDX+0x20] (record-array consumer)",
        "allocated poolguard2 bad 16-byte block",
        "allocated dd5b victim P (CHDR/world-load)",
        "world-load loop frame",
    };
    private static final String OUT_DIR =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra";

    private Memory mem;
    private PrintWriter fp;
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }

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
        fp = new PrintWriter(new File(OUT_DIR, "consumers_decomp.txt"), "UTF-8");
        try {
            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
            String bar = new String(new char[78]).replace("\0", "=");
            w("# Mercs2 array3-record consumers (over-write hunt)");
            w("# program: " + currentProgram.getName());
            w("");
            for (int i = 0; i < TARGETS.length; i++) {
                w(bar);
                w(String.format("TARGET 0x%08x  %s", TARGETS[i], LABELS[i]));
                Function f = resolveFn(TARGETS[i]);
                if (f == null) { w("  (could not resolve a containing function)"); w(""); continue; }
                w("  -> " + f.getName() + " entry=" + f.getEntryPoint()
                    + " size=" + f.getBody().getNumAddresses()
                    + " contains_target=" + f.getBody().contains(addr(TARGETS[i])));
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
