// Render-view handle-table resolve crash: pass 2.
// Decompiles the dirty-flag manager, render-mgr writer, gate writers,
// and dumps callers of the key functions. Writes to
// output/_ghidra/render_handle_decomp2.txt.
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
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceManager;
import ghidra.program.model.symbol.RefType;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;

public class DecompileRenderHandle2 extends GhidraScript {

    private static final long[] CODE_VA = {
        0x004C15E0L,  // dirty-flag manager (per-frame), called by dispatcher
        0x004C1170L,  // writes render-mgr base 017bbcc8 + flag 017bbd08
        0x004C09C0L,  // reads gate 01175a94 + registries
        0x004C00E0L,  // reads slot2 + registry A
        0x004C16E0L,  // called by invoker before resolve dispatch
        0x004C0EC0L,  // reads registry C
        0x004BBD84L,  // SET gate=1 writer (save-load?) -- force create
        0x004BC8F2L,  // gate writer -- force create
        0x004BC787L,  // gate=0 writer -- force create
        0x004BB397L,  // gate=0 writer -- force create
        0x004C2C20L   // reader of slot2 near dispatcher family
    };
    private static final String[] CODE_LBL = {
        "dirty_flag_manager_004C15E0",
        "render_mgr_writer_004C1170",
        "gate_reader_registry_004C09C0",
        "slot2_registryA_004C00E0",
        "invoker_pre_004C16E0",
        "registryC_reader_004C0EC0",
        "gate_set1_writer_004BBD84",
        "gate_writer_004BC8F2",
        "gate_zero_writer_004BC787",
        "gate_zero_writer_004BB397",
        "slot2_reader_004C2C20"
    };

    // Function entries to dump CALLERS (references-to) for.
    private static final long[] CALLEE_VA = {
        0x004C0730L,  // registry enumerator / re-init
        0x004C14F0L,  // resolve dispatcher
        0x004C15E0L,  // dirty-flag manager
        0x024611A3L,  // resolve loop
        0x004FE110L   // chain thunk
    };
    private static final String[] CALLEE_LBL = {
        "reinit_registry_enum_004C0730",
        "resolve_dispatcher_004C14F0",
        "dirty_flag_manager_004C15E0",
        "resolve_loop_024611A3",
        "chain_thunk_004FE110"
    };

    private static final long[][] DISASM_WIN = {
        {0x004C15E0L, 0x004C1700L},  // dirty manager full
        {0x004C1170L, 0x004C1300L},  // render-mgr writer
        {0x004BBD60L, 0x004BBDD0L},  // gate=1 set neighborhood
        {0x004BC780L, 0x004BC930L},  // gate writers neighborhood
    };

    private static final String OUT_DIR =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra";

    private PrintWriter fp;
    private DecompInterface decomp;
    private ConsoleTaskMonitor mon;

    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }
    private String blockOf(Address a) {
        MemoryBlock b = currentProgram.getMemory().getBlock(a);
        return b == null ? "<no block>" : b.getName();
    }

    private void decompileAt(long va, String lbl) {
        Address a = addr(va);
        FunctionManager fm = currentProgram.getFunctionManager();
        Function fn = fm.getFunctionContaining(a);
        w("================================================================");
        w(String.format("CODE 0x%08x  %s  [block=%s]", va, lbl, blockOf(a)));
        if (fn == null) {
            w("  (no function here; disassemble+create)");
            try { disassemble(a); fn = createFunction(a, null); } catch (Exception e) { w("  EXC " + e); }
            if (fn == null) fn = fm.getFunctionContaining(a);
        }
        if (fn == null) { w("  STILL none."); w(""); return; }
        w("  function: " + fn.getName() + "  entry=" + fn.getEntryPoint()
            + "  size=" + fn.getBody().getNumAddresses());
        try {
            DecompileResults res = decomp.decompileFunction(fn, 90, mon);
            if (res != null && res.decompileCompleted()) { w(""); w(res.getDecompiledFunction().getC()); }
            else w("  DECOMP FAILED: " + (res != null ? res.getErrorMessage() : "no result"));
        } catch (Exception e) { w("  DECOMP EXC: " + e); }
        w("");
    }

    private void dumpCallers(long va, String lbl) {
        Address a = addr(va);
        ReferenceManager rm = currentProgram.getReferenceManager();
        FunctionManager fm = currentProgram.getFunctionManager();
        w("----------------------------------------------------------------");
        w(String.format("CALLERS of 0x%08x  %s", va, lbl));
        int n = 0;
        for (Reference ref : rm.getReferencesTo(a)) {
            Address from = ref.getFromAddress();
            RefType rt = ref.getReferenceType();
            String kind = rt.isCall() ? "CALL " : (rt.isJump() ? "JUMP " : (rt.isData() ? "DATA " : "OTHER"));
            Function cf = fm.getFunctionContaining(from);
            String cfn = cf == null ? "<none>" : (cf.getName() + "@" + cf.getEntryPoint());
            Instruction ins = currentProgram.getListing().getInstructionAt(from);
            w(String.format("  %-5s from %s  in %s   | %s", kind, from, cfn, ins == null ? "" : ins.toString()));
            n++;
        }
        if (n == 0) w("  (no references)");
        w("  total=" + n);
        w("");
    }

    private void dumpDisasm(long start, long end) {
        Listing listing = currentProgram.getListing();
        w("================================================================");
        w(String.format("DISASM 0x%08x .. 0x%08x  [block=%s]", start, end, blockOf(addr(start))));
        Address cur = addr(start), endA = addr(end);
        int guard = 0;
        while (cur != null && cur.getOffset() <= endA.getOffset() && guard < 2000) {
            guard++;
            Instruction ins = listing.getInstructionAt(cur);
            if (ins == null) { try { disassemble(cur); } catch (Exception e) {} ins = listing.getInstructionAt(cur); }
            if (ins == null) { w(String.format("       %s  <data>", cur)); cur = cur.add(1); continue; }
            w(String.format("     %s  %s", cur, ins));
            Instruction nxt = ins.getNext();
            if (nxt == null) break;
            cur = nxt.getAddress();
        }
        w("");
    }

    @Override
    public void run() throws Exception {
        new File(OUT_DIR).mkdirs();
        File out = new File(OUT_DIR, "render_handle_decomp2.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            mon = new ConsoleTaskMonitor();
            w("# Mercs2 render-handle crash decompilation - pass 2");
            w("# md5: " + currentProgram.getExecutableMD5());
            w("");
            w("############## DECOMPILED FUNCTIONS ##############");
            for (int i = 0; i < CODE_VA.length; i++) decompileAt(CODE_VA[i], CODE_LBL[i]);
            w("############## CALLERS ##############");
            for (int i = 0; i < CALLEE_VA.length; i++) dumpCallers(CALLEE_VA[i], CALLEE_LBL[i]);
            w("############## DISASM ##############");
            for (long[] win : DISASM_WIN) dumpDisasm(win[0], win[1]);
            decomp.dispose();
        } finally { fp.close(); }
        println("wrote " + out.getAbsolutePath());
    }
}
