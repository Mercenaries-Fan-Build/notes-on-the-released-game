// Second-tier vehicle physics callees: per-wheel suspension/friction/engine, boat/heli/tank
// sub-steps, buoyancy sampler helpers, and the per-class controller command dispatchers.
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import java.io.File;
import java.io.PrintWriter;

public class DecompileVehiclePhysics2 extends GhidraScript {
    @Override
    public void run() throws Exception {
        long[] addrs = {
            // car second tier (wheel suspension/friction/engine)
            0x44f680L, 0x44e600L, 0x44f050L, 0x44f4e0L, 0x4571b0L,
            0x44fda0L, 0x44fe20L, 0x44a620L, 0x449cf0L, 0x44fc10L,
            0x44e2c0L, 0x4339d0L, 0x432a30L, 0x44cf00L, 0x44d0e0L,
            // boat sub-steps
            0x447350L, 0x447f00L, 0x4477a0L, 0x448210L, 0x446930L, 0x446460L,
            // heli sub-steps
            0x4514a0L, 0x4517b0L, 0x4516a0L, 0x452540L, 0x451ca0L, 0x4529e0L, 0x453670L, 0x450bf0L,
            // tank sub-steps
            0x4565b0L, 0x456840L, 0x455aa0L, 0x4555e0L, 0x4552d0L, 0x456250L,
            // buoyancy/floating sub-steps
            0x458dd0L, 0x458d10L, 0x458ff0L, 0x459200L, 0x459410L, 0x4591b0L, 0x458910L,
            // controller command dispatchers / per-frame vehicle controllers
            0x437300L, 0x4373b0L, 0x437720L,
        };
        File out = new File("c:/Users/Shadow/Desktop/notes-on-the-released-game/output/_ghidra/vehicle_phys_decomp2.txt");
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
