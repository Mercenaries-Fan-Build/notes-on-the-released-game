// Render-view handle-table resolve crash: decompile + xref dump.
// Targets the 0xFFFF-write crash path described in the DLC patch investigation.
// Native Ghidra Java script (Ghidra 12.x dropped bundled Jython).
// Writes C decompilation + disassembly + data xrefs to
// output/_ghidra/render_handle_decomp.txt.
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
import java.util.HashSet;
import java.util.Set;

public class DecompileRenderHandle extends GhidraScript {

    // Functions to decompile (entry or contained VA).
    private static final long[] CODE_VA = {
        0x004C14F0L,  // resolve dispatcher
        0x00630EF0L,  // per-frame render/scene tick (invoker)
        0x004C0730L,  // one-time re-init / registry enumerator
        0x004FE110L,  // chain link toward resolve loop
        0x0046A3E7L,  // worker-thread AV site
        0x00630FC7L,  // main-thread virtual-call site (inside 0x630EF0)
        0x024611A3L,  // resolve loop entry (likely .securom / undefined)
        0x024611B8L   // resolve loop body
    };
    private static final String[] CODE_LBL = {
        "resolve_dispatcher_004C14F0",
        "render_scene_tick_00630EF0 (invoker)",
        "reinit_registry_enum_004C0730",
        "chain_004FE110",
        "worker_av_site_0046A3E7",
        "main_vcall_site_00630FC7",
        "resolve_loop_entry_024611A3",
        "resolve_loop_body_024611B8"
    };

    // Data globals to dump xrefs for (READ vs WRITE).
    private static final long[] DATA_VA = {
        0x00DE8A48L,  // render-view object
        0x00DFC2F0L,  // handle table slot 0
        0x00DFC2F4L,  // handle table slot 1
        0x00DFC2F8L,  // handle table slot 2 (consumed singleton ptr)
        0x00DFC2FCL,  // handle table slot 3
        0x01175A94L,  // render-state gate (==1 path)
        0x017BBCC8L,  // render-mgr base (flag at +0x40)
        0x017BBD08L,  // render-mgr +0x40
        0x00D28668L,  // render-object registry A
        0x00D287A0L,  // render-object registry B
        0x01175FB0L   // render-object registry C
    };
    private static final String[] DATA_LBL = {
        "render_view_object_00DE8A48",
        "handle_table_slot0_00DFC2F0",
        "handle_table_slot1_00DFC2F4",
        "handle_table_slot2_singleton_00DFC2F8",
        "handle_table_slot3_00DFC2FC",
        "render_state_gate_01175A94",
        "render_mgr_base_017BBCC8",
        "render_mgr_flag40_017BBD08",
        "registry_A_00D28668",
        "registry_B_00D287A0",
        "registry_C_01175FB0"
    };

    // Disassembly windows (start,end) to dump verbatim.
    private static final long[][] DISASM_WIN = {
        {0x02461150L, 0x024613E0L},  // full resolve loop region
        {0x004C14F0L, 0x004C15E0L},  // dispatcher head
        {0x0046A3C0L, 0x0046A410L},  // worker AV neighborhood
    };
    // Sites to mark with >>> inside disasm windows.
    private static final Set<Long> MARK = new HashSet<>();
    static {
        MARK.add(0x024611A3L); MARK.add(0x024611B8L); MARK.add(0x024611CEL);
        MARK.add(0x024613BBL); MARK.add(0x024613C3L); MARK.add(0x024613C9L);
        MARK.add(0x0046A3E7L);
    }

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
            // Try to disassemble + create a function so the decompiler has something.
            w("  (no function defined here; attempting disassemble+create)");
            try {
                disassemble(a);
                fn = createFunction(a, null);
            } catch (Exception e) {
                w("  create EXC: " + e);
            }
            if (fn == null) {
                fn = fm.getFunctionContaining(a);
            }
        }
        if (fn == null) {
            w("  STILL no function (raw region likely obfuscated/.securom). See disasm dump below.");
            w("");
            return;
        }
        w("  function: " + fn.getName() + "  entry=" + fn.getEntryPoint()
            + "  size=" + fn.getBody().getNumAddresses());
        try {
            DecompileResults res = decomp.decompileFunction(fn, 90, mon);
            if (res != null && res.decompileCompleted()) {
                w("");
                w(res.getDecompiledFunction().getC());
            } else {
                w("  DECOMP FAILED: " + (res != null ? res.getErrorMessage() : "no result"));
            }
        } catch (Exception e) {
            w("  DECOMP EXC: " + e);
        }
        w("");
    }

    private void dumpXrefs(long va, String lbl) {
        Address a = addr(va);
        ReferenceManager rm = currentProgram.getReferenceManager();
        FunctionManager fm = currentProgram.getFunctionManager();
        w("----------------------------------------------------------------");
        w(String.format("XREFS to 0x%08x  %s  [block=%s]", va, lbl, blockOf(a)));
        int n = 0;
        for (Reference ref : rm.getReferencesTo(a)) {
            Address from = ref.getFromAddress();
            RefType rt = ref.getReferenceType();
            String kind = rt.isWrite() ? "WRITE" : (rt.isRead() ? "READ " : (rt.isCall() ? "CALL " : (rt.isJump() ? "JUMP " : "OTHER")));
            Function cf = fm.getFunctionContaining(from);
            String cfn = cf == null ? "<none>" : (cf.getName() + "@" + cf.getEntryPoint());
            Instruction ins = currentProgram.getListing().getInstructionAt(from);
            String insTxt = ins == null ? "" : ins.toString();
            w(String.format("  %-5s from %s  in %s   | %s", kind, from, cfn, insTxt));
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
        Address cur = addr(start);
        Address endA = addr(end);
        int guard = 0;
        while (cur != null && cur.getOffset() <= endA.getOffset() && guard < 4000) {
            guard++;
            Instruction ins = listing.getInstructionAt(cur);
            if (ins == null) {
                // try to disassemble here
                try { disassemble(cur); } catch (Exception e) {}
                ins = listing.getInstructionAt(cur);
            }
            if (ins == null) {
                w(String.format("       %s  <data/undefined>", cur));
                cur = cur.add(1);
                continue;
            }
            String marker = MARK.contains(cur.getOffset()) ? "  >>>" : "     ";
            w(String.format("%s %s  %s", marker, cur, ins));
            Instruction nxt = ins.getNext();
            if (nxt == null) break;
            cur = nxt.getAddress();
        }
        w("");
    }

    @Override
    public void run() throws Exception {
        new File(OUT_DIR).mkdirs();
        File out = new File(OUT_DIR, "render_handle_decomp.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            mon = new ConsoleTaskMonitor();

            w("# Mercs2 render-view handle-table resolve crash decompilation");
            w("# program: " + currentProgram.getName());
            w("# image base: " + currentProgram.getImageBase());
            w("# md5: " + currentProgram.getExecutableMD5());
            w("");
            w("# MEMORY BLOCKS:");
            for (MemoryBlock b : currentProgram.getMemory().getBlocks()) {
                w(String.format("#   %-12s %s .. %s  %s%s%s",
                    b.getName(), b.getStart(), b.getEnd(),
                    b.isRead()?"r":"-", b.isWrite()?"w":"-", b.isExecute()?"x":"-"));
            }
            w("");

            w("############## DECOMPILED FUNCTIONS ##############");
            for (int i = 0; i < CODE_VA.length; i++) decompileAt(CODE_VA[i], CODE_LBL[i]);

            w("############## DATA XREFS ##############");
            for (int i = 0; i < DATA_VA.length; i++) dumpXrefs(DATA_VA[i], DATA_LBL[i]);

            w("############## RAW DISASSEMBLY WINDOWS ##############");
            for (long[] win : DISASM_WIN) dumpDisasm(win[0], win[1]);

            decomp.dispose();
        } finally {
            fp.close();
        }
        println("wrote " + out.getAbsolutePath());
    }
}
