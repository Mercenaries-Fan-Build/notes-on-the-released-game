// Decompile the component-record LOAD-STEP that poolguard v12's timeline named as the corruptor.
// The 0x0047xxxx loop (ends each pass at 0x00414B0B allocating a 16-byte record) builds an array
// of 16-byte records; the dd5b victim is a 16-byte block. We want the record-array allocation size
// vs the write/count loop -> the off-by-one (one record written past the buffer).
//
// Targets (from the poolguard.log timeline + the 0x4CC064 stack walk):
//   0x00414B0B  per-entity 16-byte record alloc (END of each loop iteration) -- prime suspect
//   0x004714B4  loop body (per-entity small allocs)
//   0x00470F00  loop start
//   0x0046FE50  obj builder (calls 0x470BC0; obj has count@+0x7C, word[]@+0x8C)
//   0x005A030D  component factory (16-byte DCE0 + Pool2 body pattern)
//   0x004C9C80  outer world-load loop
// Writes output/_ghidra/loadstep_decomp.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.mem.Memory;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;

public class DecompileLoadStep extends GhidraScript {

    private static final long[] TARGETS = {
        0x00414B0BL, 0x004714B4L, 0x00470F00L, 0x0046FE50L, 0x005A030DL, 0x004C9C80L,
    };
    private static final String[] LABELS = {
        "FUN @0x00414B0B  per-entity 16-byte record alloc (prime suspect)",
        "FUN @0x004714B4  loop body (per-entity small allocs)",
        "FUN @0x00470F00  loop start",
        "FUN @0x0046FE50  obj builder (calls 0x470BC0)",
        "FUN @0x005A030D  component factory (DCE0 16 + Pool2 body)",
        "FUN @0x004C9C80  outer world-load loop",
    };
    private static final String OUT_DIR =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra";

    private PrintWriter fp;
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }

    private Function ensureFn(long va) throws Exception {
        FunctionManager fm = currentProgram.getFunctionManager();
        Function f = fm.getFunctionContaining(addr(va));
        if (f != null) return f;
        Memory mem = currentProgram.getMemory();
        long e = -1;
        for (long a = va; a > va - 0x6000; a--) {
            try {
                if ((mem.getByte(addr(a)) & 0xff) == 0x55 &&
                    (mem.getByte(addr(a + 1)) & 0xff) == 0x8b &&
                    (mem.getByte(addr(a + 2)) & 0xff) == 0xec) { e = a; break; }
            } catch (Exception ex) { }
        }
        if (e < 0) return null;
        disassemble(addr(e));
        f = createFunction(addr(e), null);
        if (f == null) f = fm.getFunctionContaining(addr(va));
        return f;
    }

    @Override
    public void run() throws Exception {
        new File(OUT_DIR).mkdirs();
        File out = new File(OUT_DIR, "loadstep_decomp.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
            String bar = new String(new char[78]).replace("\0", "=");
            w("# Mercs2 component-record load-step (16-byte-record over-write hunt)");
            w("# program: " + currentProgram.getName());
            w("");
            for (int i = 0; i < TARGETS.length; i++) {
                w(bar);
                w(String.format("TARGET 0x%08x  %s", TARGETS[i], LABELS[i]));
                Function f = ensureFn(TARGETS[i]);
                if (f == null) { w("  (could not define function)"); w(""); continue; }
                w("  " + f.getName() + " entry=" + f.getEntryPoint()
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
