// Vehicle physics actors (hkpUnaryAction-derived) — the drive model cluster.
// Root cause of prior unreadability: FUN_00401740 (x87 SQRT helper) was marked noreturn,
// so every prior decomp export truncated the vehicle step functions at their first sqrt call.
// This script clears the noreturn flag (and on its neighbors' thunks if flagged), then
// re-decompiles the whole vehicle actor cluster to output/_ghidra/vehicle_phys_decomp.txt.
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import java.io.File;
import java.io.PrintWriter;

public class DecompileVehiclePhysics extends GhidraScript {
    @Override
    public void run() throws Exception {
        // 1) fix falsely-noreturn math helpers
        long[] fix = {0x401740L, 0x401750L, 0x4017a0L, 0x401630L};
        for (long a : fix) {
            Function f = getFunctionAt(toAddr(a));
            if (f != null && f.hasNoReturn()) {
                f.setNoReturn(false);
                println("cleared noreturn on " + f.getName());
            }
        }
        long[] addrs = {
            // class A (vt 0xba9340)
            0x435300L, 0x447260L, 0x447300L, 0x446bd0L, 0x435e10L, 0x4465e0L,
            0x435660L, 0x435530L, 0x435790L, 0x435b20L,
            // class B (vt 0xba9858)
            0x4391f0L, 0x453760L, 0x4391d0L, 0x439fd0L, 0x43a1b0L, 0x439540L,
            0x439850L, 0x453090L,
            // class C = CarPhysicsV2 (vt 0xbaa360)
            0x437080L, 0x437260L, 0x437280L, 0x449460L, 0x449440L, 0x44db60L,
            0x44cc90L, 0x44ce10L, 0x44d9b0L, 0x44e2c0L, 0x44eb50L, 0x44df60L,
            0x44de50L, 0x44eac0L, 0x44ea40L, 0x44a550L, 0x44a6a0L, 0x44a970L,
            0x44d430L, 0x44d290L, 0x44d3b0L, 0x449dc0L, 0x470620L,
            // classes D/E (vt 0xbaa388 / 0xbaa3b0) + factory
            0x432280L, 0x450130L, 0x4507e0L, 0x450280L, 0x4508a0L, 0x4505e0L,
            0x450cf0L, 0x451140L, 0x451360L, 0x4500c0L,
            // class F (vt 0xbaa400) + factory
            0x433530L, 0x453ca0L, 0x453ce0L,
            // class G (vt 0xbaa470)
            0x454a70L, 0x454d80L, 0x454ae0L, 0x455210L, 0x453fc0L, 0x454200L,
            // classes H/I (vt 0xbaa4c4 / 0xbaa4ec)
            0x4573d0L, 0x4574f0L, 0x4577c0L, 0x458ac0L, 0x457800L, 0x458270L, 0x457410L,
            // shared vtable tail virtuals (A/B/D/E/G family)
            0x43d1b0L, 0x440b40L, 0x4027b0L, 0x42ee50L, 0x42ff40L, 0x42ffd0L,
            0x430060L, 0x4300e0L, 0x430120L, 0x4301a0L, 0x430280L, 0x4302f0L,
            0x430340L, 0x42c090L, 0x42c0a0L, 0x430950L, 0x430990L, 0x430390L,
            0x4303c0L, 0x430400L, 0x441da0L,
        };
        File out = new File("c:/Users/Shadow/Desktop/notes-on-the-released-game/output/_ghidra/vehicle_phys_decomp.txt");
        PrintWriter pw = new PrintWriter(out, "UTF-8");
        DecompInterface ifc = new DecompInterface();
        ifc.openProgram(currentProgram);
        try {
            for (long a : addrs) {
                Address addr = toAddr(a);
                Function f = getFunctionAt(addr);
                if (f == null) {
                    disassemble(addr);
                    f = createFunction(addr, null);
                }
                pw.println("============================================================");
                pw.println("==== " + (f == null ? "??" : f.getName()) + " @0x" + Long.toHexString(a) + " ====");
                if (f == null) { pw.println("!! could not create function"); continue; }
                DecompileResults res = ifc.decompileFunction(f, 120, monitor);
                if (res.decompileCompleted()) {
                    pw.println(res.getDecompiledFunction().getC());
                } else {
                    pw.println("!! decompile failed: " + res.getErrorMessage());
                }
                pw.flush();
            }
        } finally {
            ifc.dispose();
            pw.close();
        }
        println("wrote " + out.getAbsolutePath());
    }
}
