// Decompile the 0x4CC064 type-confusion crash path (grid/spatial table cell holds a texture-record
// address treated as an object). Identify the +0x08 table structure + find its producer.
//   0x00873228  CONSUMER: ecx=table[idx]=[ebp+idx*4+0x08]; call (*ecx)[0xC]  (virtual-call on entry)
//   0x004CC030  __thiscall pool-pop helper: reads [this+0x78010] count, [this+0x7300C] table  (crash)
//   0x004CBF80  builds the +0x7300C table from 0x1A4-byte records (sub eax,0x1A4 loop)
//   0x004CC130  caller that virtual-dispatches into 0x4CC030
// Writes output/_ghidra/gridcrash_decomp.txt.
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

public class DecompileGridCrash extends GhidraScript {

    private static final long[] TARGETS = { 0x00873228L, 0x004CC030L, 0x004CBF80L, 0x004CC130L };
    private static final String[] LABELS = {
        "consumer: virtual-call on table[idx]=[ebp+idx*4+0x08]",
        "pool-pop helper [this+0x78010]/[this+0x7300C] (crash 0x4CC064)",
        "builder of +0x7300C table from 0x1A4-byte records",
        "caller that dispatches into 0x4CC030",
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
            try { while (start < va) { int b = mem.getByte(addr(start)) & 0xff;
                if (b == 0xCC || b == 0x90) start++; else break; } } catch (Exception ex) { break; }
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
        fp = new PrintWriter(new File(OUT_DIR, "gridcrash_decomp.txt"), "UTF-8");
        try {
            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
            String bar = new String(new char[78]).replace("\0", "=");
            w("# Mercs2 0x4CC064 grid type-confusion crash path"); w("");
            for (int i = 0; i < TARGETS.length; i++) {
                w(bar);
                w(String.format("TARGET 0x%08x  %s", TARGETS[i], LABELS[i]));
                Function f = resolveFn(TARGETS[i]);
                if (f == null) { w("  (unresolved)"); w(""); continue; }
                w("  -> " + f.getName() + " entry=" + f.getEntryPoint()
                    + " size=" + f.getBody().getNumAddresses());
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
