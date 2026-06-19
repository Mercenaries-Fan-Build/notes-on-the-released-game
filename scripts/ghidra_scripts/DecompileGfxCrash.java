// Decompile the GFx (Scaleform) UI-loader crash 0x007939C0
// (mov edx,[edx+0x2C], edx=0 from eax->field10 NULL; eax=ebx->field188 = zeroed obj)
// and its callers, + xrefs to the ebx vtable 0x00BDB410. Writes to
// output/_ghidra/gfx_crash_decomp.txt.
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

public class DecompileGfxCrash extends GhidraScript {

    private static final long[] TARGET_VA = {
        0x007939C0L, // crash: mov edx,[edx+0x2C], edx=0 (eax->field10 null; eax=ebx->188 zeroed)
        0x00790F02L, // caller
        0x007E0404L, // caller
        0x00790FE2L, // caller
    };
    private static final String[] TARGET_LBL = {
        "CRASH fn 0x7939C0 (eax=ebx->188 zeroed obj; eax->field10 null -> deref)",
        "caller 0x790F02",
        "caller 0x7E0404",
        "caller 0x790FE2",
    };
    private static final long VTABLE_VA = 0x00BDB410L; // ebx (GFx object) vtable
    private static final long FAULT_SITE = 0x007939C0L;

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
        File out = new File(OUT_DIR, "gfx_crash_decomp.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            FunctionManager fm = currentProgram.getFunctionManager();
            Listing listing = currentProgram.getListing();
            ReferenceManager rm = currentProgram.getReferenceManager();
            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();

            w("# Mercs2 GFx UI-loader crash 0x007939C0");
            w("# program: " + currentProgram.getName());
            w("");
            String bar = new String(new char[78]).replace("\0", "=");

            w(bar);
            w(String.format("XREFS to vtable 0x%08x (ebx class constructor):", VTABLE_VA));
            int nref = 0;
            for (Reference r : rm.getReferencesTo(addr(VTABLE_VA))) {
                Function cf = fm.getFunctionContaining(r.getFromAddress());
                w(String.format("  from 0x%08x %s in %s", r.getFromAddress().getOffset(),
                    r.getReferenceType(), cf != null ? (cf.getName()+" @ "+cf.getEntryPoint()) : "(no fn)"));
                if (++nref >= 10) { w("  ..."); break; }
            }
            if (nref == 0) w("  (none)");
            w("");

            Set<Long> seen = new HashSet<>();
            for (int i = 0; i < TARGET_VA.length; i++) {
                long va = TARGET_VA[i];
                Function fn = fm.getFunctionContaining(addr(va));
                w(bar);
                w(String.format("TARGET 0x%08x  %s", va, TARGET_LBL[i]));
                if (fn == null) { w("  (no function defined)"); w(""); continue; }
                long key = fn.getEntryPoint().getOffset();
                w("  function: " + fn.getName() + "  entry=" + fn.getEntryPoint()
                    + "  size=" + fn.getBody().getNumAddresses());
                if (seen.contains(key)) { w("  (already decompiled above)"); w(""); continue; }
                seen.add(key);
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

            w(bar);
            w(String.format("DISASSEMBLY around fault 0x%08x (+/- 0x40):", FAULT_SITE));
            Address cur = addr(FAULT_SITE - 0x40), end = addr(FAULT_SITE + 0x40);
            while (cur != null && cur.getOffset() <= end.getOffset()) {
                Instruction ins = listing.getInstructionAt(cur);
                if (ins == null) { cur = cur.add(1); continue; }
                w((cur.getOffset() == FAULT_SITE ? "  >>>" : "     ") + " " + cur + "  " + ins);
                Instruction nxt = ins.getNext();
                if (nxt == null) break;
                cur = nxt.getAddress();
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("wrote " + out.getAbsolutePath());
    }
}
