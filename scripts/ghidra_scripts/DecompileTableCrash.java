// Decompile the NULL-table-entry crash 0x004CC064 (mov eax,[esi], esi=0 = a
// null slot in a table at object+0x7300C, iterated one past the valid entries).
// Identify the loop bound/count source. Writes output/_ghidra/table_crash_decomp.txt.
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

public class DecompileTableCrash extends GhidraScript {

    private static final long[] TARGET_VA = {
        0x004CC064L, // crash: mov eax,[esi], esi=0 (null table slot)
        0x004CC180L, // caller
        0x00873236L, // caller
        0x004B0EC0L, // per-entry callee (called at 0x4cc05b when slot != 0)
    };
    private static final String[] TARGET_LBL = {
        "CRASH fn 0x4CC064 (null slot in table @ obj+0x7300C; iterated 1 past end)",
        "caller 0x4CC180",
        "caller 0x873236",
        "per-entry callee 0x4B0EC0",
    };
    private static final long FAULT_SITE = 0x004CC064L;
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
        File out = new File(OUT_DIR, "table_crash_decomp.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            FunctionManager fm = currentProgram.getFunctionManager();
            Listing listing = currentProgram.getListing();
            ReferenceManager rm = currentProgram.getReferenceManager();
            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();

            w("# Mercs2 null-table-entry crash 0x004CC064");
            w("# program: " + currentProgram.getName());
            w("");
            String bar = new String(new char[78]).replace("\0", "=");

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
                int nc = 0;
                for (Reference r : rm.getReferencesTo(fn.getEntryPoint())) {
                    if (!r.getReferenceType().isCall()) continue;
                    Function cf = fm.getFunctionContaining(r.getFromAddress());
                    w(String.format("    caller 0x%08x %s", r.getFromAddress().getOffset(),
                        cf != null ? cf.getName() : "(no fn)"));
                    if (++nc >= 8) { w("    ..."); break; }
                }
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
            w(String.format("DISASSEMBLY around fault 0x%08x (+/- 0x50):", FAULT_SITE));
            Address cur = addr(FAULT_SITE - 0x50), end = addr(FAULT_SITE + 0x30);
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
