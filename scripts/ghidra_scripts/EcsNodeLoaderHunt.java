// Hunt the ECS-node loader / scene populator and the per-entity component-table writer.
// Strategy:
//  A. Find every function that references the ECS-node / worldentity / guidmap / texture type hashes
//     as immediate constants (0xE6B81A54, 0x5647C35D, 0x140E8728, 0xF011157A, 0x56471E89 seen in
//     scene ctor, plus mesh 0x5B724250). List them so we can see the type dispatch table.
//  B. Find the component-container "add" function: the writer that does table[count]={id,ptr};count++
//     on a {table,count,cap} struct. We approach via callers of the allocator pattern that build
//     entity+0xA0. Concretely: decompile callers of FUN_007E0420 / FUN_007E0280 region siblings and
//     any function that writes [reg+0xA0] then a count. Instead we enumerate xrefs to the scene
//     ctor FUN_007C5970 (who builds the scene) and the worldentity ctor FUN_007BB1A0 / FUN_007BEF60
//     referenced inside it, decompiling each.
//  C. Scan instructions for the constant 0xA0 used as a displacement near a call (component
//     registration) - too broad; instead we follow the type-hash referrers.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.scalar.Scalar;
import ghidra.program.model.symbol.Reference;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.TreeSet;

public class EcsNodeLoaderHunt extends GhidraScript {
    private static final long[] TYPE_HASHES = {
        0xE6B81A54L, // ECS_NODE
        0x5647C35DL, // worldentity
        0x140E8728L, // guidmap
        0xF011157AL, // texture
        0x56471E89L, // seen in scene ctor allocations (entity/worldentity tag?)
        0x5B724250L, // MESH
        0x9FE1234AL  // DAT_9fe1234a written next to 0x56471E89 in scene ctor
    };
    private static final long[] DIRECT = {
        0x007BB1A0L, 0x007BEF60L, 0x007677F0L, // ctors referenced in scene ctor
        0x004A2CE0L, 0x004A01E0L              // referenced in FUN_004a0c40
    };
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\ecs_node_loader.txt";
    private PrintWriter fp;
    private DecompInterface decomp;
    private ConsoleTaskMonitor mon;
    private final Set<Long> done = new LinkedHashSet<>();
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }
    private void decompileVa(long va, String tag) {
        Function f = getFunctionContaining(addr(va));
        if (f == null) { try { disassemble(addr(va)); f = createFunction(addr(va), null); } catch (Exception e) {} }
        if (f == null) { w("  (no fn @0x" + Long.toHexString(va) + ") " + tag); return; }
        long key = f.getEntryPoint().getOffset();
        if (!done.add(key)) { w("  (dup " + f.getName() + ") " + tag); return; }
        try {
            DecompileResults res = decomp.decompileFunction(f, 120, mon);
            w("  >>> " + f.getName() + " @" + f.getEntryPoint() + "  " + tag);
            if (res != null && res.decompileCompleted()) w(res.getDecompiledFunction().getC());
            else w("    DECOMP FAIL");
        } catch (Exception e) { w("    EXC " + e); }
    }
    @Override
    public void run() throws Exception {
        new File(OUT).getParentFile().mkdirs();
        fp = new PrintWriter(new File(OUT), "UTF-8");
        decomp = new DecompInterface(); decomp.openProgram(currentProgram);
        mon = new ConsoleTaskMonitor();
        try {
            // A. scan instructions for type-hash immediates
            Set<Long> hashSet = new TreeSet<>();
            for (long h : TYPE_HASHES) hashSet.add(h & 0xFFFFFFFFL);
            w("############### functions referencing type-hash immediates ###############");
            Set<Long> hashFns = new LinkedHashSet<>();
            InstructionIterator it = currentProgram.getListing().getInstructions(true);
            while (it.hasNext()) {
                Instruction ins = it.next();
                int n = ins.getNumOperands();
                for (int oi = 0; oi < n; oi++) {
                    Object[] objs = ins.getOpObjects(oi);
                    for (Object o : objs) {
                        if (o instanceof Scalar) {
                            long val = ((Scalar) o).getUnsignedValue() & 0xFFFFFFFFL;
                            if (hashSet.contains(val)) {
                                Function ff = getFunctionContaining(ins.getAddress());
                                w(String.format("  0x%08x  %-8s  hash=0x%08x  [%s]",
                                    ins.getAddress().getOffset(), ins.getMnemonicString(), val,
                                    ff != null ? ff.getName() : "?"));
                                if (ff != null) hashFns.add(ff.getEntryPoint().getOffset());
                            }
                        }
                    }
                }
            }
            w("");
            w("############### decompiled type-hash referrer functions ###############");
            for (long va : hashFns) decompileVa(va, "type-hash referrer");

            w("");
            w("############### DIRECT ctors/helpers ###############");
            for (long t : DIRECT) decompileVa(t, "direct");
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
