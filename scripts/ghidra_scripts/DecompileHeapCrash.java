// Decompile the deterministic pool-allocator crash 0x0084DD5B
// (mov edx,[esi], esi = free-list head 0xD28FA5B0, unmapped) and its callers,
// to identify what pool/subsystem this is. Writes to
// output/_ghidra/heap_crash_decomp.txt.
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

public class DecompileHeapCrash extends GhidraScript {

    private static final long[] TARGET_VA = {
        0x0084DD5BL, // crash: free-list pop (mov edx,[esi])
        0x0084AC8AL, // immediate caller (return on stack)
        0x0067A9C8L, // .text caller (the allocating subsystem)
        0x0084AC20L, // alloc entry (the malloc the Havok loader calls)
    };
    private static final String[] TARGET_LBL = {
        "CRASH fn 0x84DD5B (pool free-list pop; head=0xD28FA5B0 unmapped)",
        "caller 0x84AC8A",
        ".text caller 0x67A9C8 (allocating subsystem)",
        "alloc entry 0x84AC20",
    };
    private static final long FAULT_SITE = 0x0084DD5BL;

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
        File out = new File(OUT_DIR, "heap_crash_decomp.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            FunctionManager fm = currentProgram.getFunctionManager();
            Listing listing = currentProgram.getListing();
            ReferenceManager rm = currentProgram.getReferenceManager();
            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();

            w("# Mercs2 deterministic pool-corruption crash 0x0084DD5B");
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
                // who calls this function?
                int nc = 0;
                w("  callers:");
                for (Reference r : rm.getReferencesTo(fn.getEntryPoint())) {
                    if (!r.getReferenceType().isCall()) continue;
                    Function cf = fm.getFunctionContaining(r.getFromAddress());
                    w(String.format("    <- 0x%08x %s", r.getFromAddress().getOffset(),
                        cf != null ? cf.getName() : "(no fn)"));
                    if (++nc >= 12) { w("    ..."); break; }
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
