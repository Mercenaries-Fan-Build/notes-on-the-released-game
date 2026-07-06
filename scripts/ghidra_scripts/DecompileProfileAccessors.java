// Decompile the six native profile accessors that auto-analysis missed (they are reached only
// through the LTI Lua-binding table at file 0x799280, never by direct call):
//   0x5df790 GetProfileCharacter   0x5df7d0 SetProfileCharacter
//   0x5df830 GetProfileUpgrade     0x5df870 SetProfileUpgrade
//   0x5df8e0 GetProfileCostume     0x5df920 SetProfileCostume
// plus 0x5df980 (known-good neighbor, sanity reference). Functions are created if absent, then
// decompiled; output goes to the console (redirected by the headless run).
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;

public class DecompileProfileAccessors extends GhidraScript {
    @Override
    public void run() throws Exception {
        long[] addrs = {0x5df790L, 0x5df7d0L, 0x5df830L, 0x5df870L, 0x5df8e0L, 0x5df920L, 0x5df980L};
        String[] names = {
            "GetProfileCharacter", "SetProfileCharacter", "GetProfileUpgrade",
            "SetProfileUpgrade", "GetProfileCostume", "SetProfileCostume", "REF_FUN_005df980",
        };
        DecompInterface ifc = new DecompInterface();
        ifc.openProgram(currentProgram);
        try {
            for (int i = 0; i < addrs.length; i++) {
                Address addr = toAddr(addrs[i]);
                Function f = getFunctionAt(addr);
                if (f == null) {
                    disassemble(addr);
                    f = createFunction(addr, null);
                }
                println("==== " + names[i] + " @ " + addr + " ====");
                if (f == null) {
                    println("!! could not create function");
                    continue;
                }
                DecompileResults res = ifc.decompileFunction(f, 90, monitor);
                if (res.decompileCompleted()) {
                    println(res.getDecompiledFunction().getC());
                } else {
                    println("!! decompile failed: " + res.getErrorMessage());
                }
            }
        } finally {
            ifc.dispose();
        }
    }
}
