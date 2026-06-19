// Trace the producer of the corrupt texture-component object (crash @0x7E0465).
// Live findings:
//   iterator   FUN_007E0420  virtual-calls table[i].ptr -> vtable[2]; crashed on a tex-record array.
//   caller     contains 0x007919D0 (call FUN_007E0420); entity+0xA0 = component container.
//   FUN_007DCC70 called just before (component lookup/build?).
//   vtable cluster in image: 0x00BDB404 / 0x00BDB410 / 0x00BDB534 / 0x00BDB540
//      (entity vtable=0x00BDB410; bad object stored 0x00BDB413 = 0x00BDB410 with low bits polluted).
//   texture component type hash = 0xF011157A.
// This script:
//   1. Decompiles FUN_007E0420, the caller of 0x007919D0, and FUN_007DCC70.
//   2. Lists + decompiles the CONSTRUCTORS that store each cluster vtable (xrefs to the vtable addrs)
//      -> names the classes (which component / entity).
//   3. Finds code refs to the constant 0xF011157A (texture builder sites) and decompiles them.
// Writes output/_ghidra/texcomp_producer.txt.
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

public class TexCompProducer extends GhidraScript {
    private static final long[] CLUSTER = { 0x00BDB404L, 0x00BDB410L, 0x00BDB534L, 0x00BDB540L };
    private static final long[] DIRECT  = { 0x007E0420L, 0x007919D0L, 0x007DCC70L };
    private static final long TEX_HASH = 0xF011157AL;
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\texcomp_producer.txt";
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
        if (f == null) { w("  (no function at 0x" + Long.toHexString(va) + ") " + tag); return; }
        long key = f.getEntryPoint().getOffset();
        if (!done.add(key)) { w("  (already decompiled " + f.getName() + ") " + tag); return; }
        try {
            DecompileResults res = decomp.decompileFunction(f, 90, mon);
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
            w("############### DIRECT TARGETS ###############");
            decompileVa(0x007E0420L, "iterator FUN_007E0420");
            decompileVa(0x007919D0L, "caller of FUN_007E0420");
            decompileVa(0x007DCC70L, "FUN_007DCC70 (pre-call)");

            w("");
            w("############### VTABLE CLUSTER CONSTRUCTORS ###############");
            for (long vt : CLUSTER) {
                w("======= refs to vtable 0x" + Long.toHexString(vt) + " =======");
                Reference[] refs = getReferencesTo(addr(vt));
                for (Reference r : refs) {
                    Address from = r.getFromAddress();
                    Function ff = getFunctionContaining(from);
                    w(String.format("  from 0x%08x  %s  [%s]", from.getOffset(), r.getReferenceType(),
                        ff != null ? ff.getName() : "DATA"));
                }
            }
            w("");
            w("--- decompiled cluster constructors (code refs) ---");
            for (long vt : CLUSTER) {
                for (Reference r : getReferencesTo(addr(vt))) {
                    Function ff = getFunctionContaining(r.getFromAddress());
                    if (ff != null) decompileVa(r.getFromAddress().getOffset(),
                        "stores vtable 0x" + Long.toHexString(vt));
                }
            }

            w("");
            w("############### TEX HASH 0xF011157A CODE SITES ###############");
            // scan instructions for an immediate operand == 0xF011157A
            InstructionIterator it = currentProgram.getListing().getInstructions(true);
            Set<Long> hashFns = new LinkedHashSet<>();
            int hits = 0;
            while (it.hasNext() && hits < 4000) {
                Instruction ins = it.next();
                for (int oi = 0; oi < ins.getNumOperands(); oi++) {
                    Object[] objs = ins.getOpObjects(oi);
                    for (Object o : objs) {
                        if (o instanceof Scalar) {
                            long val = ((Scalar) o).getUnsignedValue() & 0xFFFFFFFFL;
                            if (val == TEX_HASH) {
                                Function ff = getFunctionContaining(ins.getAddress());
                                w(String.format("  0x%08x  %s  [%s]", ins.getAddress().getOffset(),
                                    ins.toString(), ff != null ? ff.getName() : "?"));
                                if (ff != null) hashFns.add(ff.getEntryPoint().getOffset());
                                hits++;
                            }
                        }
                    }
                }
            }
            w("");
            w("--- decompiled functions referencing 0xF011157A ---");
            for (long fn : hashFns) decompileVa(fn, "refs 0xF011157A");

            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
