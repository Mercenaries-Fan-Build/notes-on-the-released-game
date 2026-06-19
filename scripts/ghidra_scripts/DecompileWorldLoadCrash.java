// Decompile the world-load NULL-write crash 0x004CF58B (mov [eax],edi, eax=0)
// and its caller chain, plus xrefs to the crashing object's vtable 0x00BB12B4
// (to identify the class via its constructor). Writes to
// output/_ghidra/worldload_crash_decomp.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Listing;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceManager;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.util.HashSet;
import java.util.Set;

public class DecompileWorldLoadCrash extends GhidraScript {

    // crash fn + the 6 live call-stack return-address functions, then the
    // 6 vtable methods at 0x00BB12B4 (esi class).
    private static final long[] TARGET_VA = {
        0x004CF340L, // crash function (mov [eax],edi @ 0x4CF58B)
        0x005FD580L, // immediate trampoline caller
        0x0046FE50L, 0x004B11D8L, 0x004C9C80L, 0x004C0EDBL, 0x004C0B6FL, // up the stack
        0x004CF1E0L, 0x004BE2D0L, 0x00772570L, 0x004F2900L, 0x004CF0D0L, 0x006C8210L // vtable[0..5]
    };
    private static final String[] TARGET_LBL = {
        "CRASH FN 0x4CF340 (this=esi vtbl 0xBB12B4; null inner array [ebp-0x14])",
        "trampoline caller 0x5FD580",
        "caller 0x46FE50", "caller 0x4B11D8", "caller 0x4C9C80",
        "caller 0x4C0EDB", "caller 0x4C0B6F (outermost)",
        "vtbl[0] 0x4CF1E0", "vtbl[1] 0x4BE2D0", "vtbl[2] 0x772570",
        "vtbl[3] 0x4F2900", "vtbl[4] 0x4CF0D0", "vtbl[5] 0x6C8210"
    };
    private static final long VTABLE_VA = 0x00BB12B4L;
    private static final long FAULT_SITE = 0x004CF58BL;

    private static final String OUT_DIR =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra";

    private PrintWriter fp;
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }

    @Override
    public void run() throws Exception {
        new File(OUT_DIR).mkdirs();
        File out = new File(OUT_DIR, "worldload_crash_decomp.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            FunctionManager fm = currentProgram.getFunctionManager();
            Listing listing = currentProgram.getListing();
            ReferenceManager rm = currentProgram.getReferenceManager();

            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();

            w("# Mercs2 world-load crash 0x004CF58B decompilation");
            w("# program: " + currentProgram.getName());
            w("# image base: " + currentProgram.getImageBase());
            w("");

            String bar = new String(new char[78]).replace("\0", "=");

            // ── XREFS to the vtable: the constructor that writes 0xBB12B4 names the class
            w(bar);
            w(String.format("XREFS to vtable 0x%08x (constructor sites identify the class):", VTABLE_VA));
            Address vt = addr(VTABLE_VA);
            int nref = 0;
            for (Reference r : rm.getReferencesTo(vt)) {
                Address from = r.getFromAddress();
                Function cf = fm.getFunctionContaining(from);
                w(String.format("  from 0x%08x  %s  in %s",
                    from.getOffset(), r.getReferenceType(),
                    cf != null ? (cf.getName() + " @ " + cf.getEntryPoint()) : "(no fn)"));
                nref++;
            }
            if (nref == 0) w("  (no direct references found to the vtable address)");
            w("");

            // ── Decompile each target function
            Set<Long> seen = new HashSet<>();
            for (int i = 0; i < TARGET_VA.length; i++) {
                long va = TARGET_VA[i];
                Address a = addr(va);
                Function fn = fm.getFunctionContaining(a);
                w(bar);
                w(String.format("TARGET 0x%08x  %s", va, TARGET_LBL[i]));
                if (fn == null) { w("  (no function defined here)"); w(""); continue; }
                long key = fn.getEntryPoint().getOffset();
                if (seen.contains(key)) {
                    w("  (same function as a previous target: " + fn.getName()
                        + " @ " + fn.getEntryPoint() + ")"); w(""); continue;
                }
                seen.add(key);
                w("  function: " + fn.getName() + "  entry=" + fn.getEntryPoint()
                    + "  size=" + fn.getBody().getNumAddresses());
                try {
                    DecompileResults res = decomp.decompileFunction(fn, 60, mon);
                    if (res != null && res.decompileCompleted()) {
                        w(""); w(res.getDecompiledFunction().getC());
                    } else {
                        w("  DECOMP FAILED: " + (res != null ? res.getErrorMessage() : "no result"));
                    }
                } catch (Exception e) { w("  DECOMP EXC: " + e); }
                w("");
            }

            // ── Disassembly around the fault
            w(bar);
            w(String.format("DISASSEMBLY around fault 0x%08x (+/- 0x40):", FAULT_SITE));
            Address cur = addr(FAULT_SITE - 0x40);
            Address end = addr(FAULT_SITE + 0x40);
            while (cur != null && cur.getOffset() <= end.getOffset()) {
                Instruction ins = listing.getInstructionAt(cur);
                if (ins == null) { cur = cur.add(1); continue; }
                String marker = (cur.getOffset() == FAULT_SITE) ? "  >>>" : "     ";
                w(marker + " " + cur + "  " + ins);
                Instruction nxt = ins.getNext();
                if (nxt == null) break;
                cur = nxt.getAddress();
            }
            decomp.dispose();
        } finally {
            fp.close();
        }
        println("wrote " + out.getAbsolutePath());
    }
}
