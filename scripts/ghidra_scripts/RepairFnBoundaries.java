// Repair mis-analyzed function boundaries before re-exporting the decomp.
// Ghidra's auto-analysis split the FESL version-compute function wrong: it created a
// bogus FUN_006c8cbf over inter-function padding and never defined the real __fastcall
// function that begins at 0x006c8cd0 (verified against the live image). This clears the
// bogus function + padding and (re)creates the real ones, then the program is saved so
// the subsequent DecompileAllFunctions export (and all future exports) come out clean.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;

public class RepairFnBoundaries extends GhidraScript {
    // True entry points to (re)create.
    private static final long[] ENTRIES = { 0x006c8cd0L };
    // {start, exclusiveEnd} ranges of bogus functions / junk to remove first.
    private static final long[][] CLEAR = { {0x006c8cbfL, 0x006c8cd0L} };

    private Address a(long v) { return toAddr(v); }

    @Override
    public void run() throws Exception {
        for (long[] c : CLEAR) {
            Address s = a(c[0]), e = a(c[1] - 1);
            Function bad = getFunctionAt(s);
            if (bad != null) { println("remove bogus fn " + bad.getName() + " @" + s); removeFunction(bad); }
            clearListing(s, e);
            println("cleared " + s + ".." + e);
        }
        for (long ent : ENTRIES) {
            Address e = a(ent);
            Function over = getFunctionContaining(e);
            if (over != null && over.getEntryPoint().getOffset() != ent) {
                println("remove overlapping fn " + over.getName() + " @" + over.getEntryPoint());
                removeFunction(over);
            }
            Function atE = getFunctionAt(e);
            if (atE != null) removeFunction(atE);
            if (getInstructionAt(e) == null) disassemble(e);
            Function f = createFunction(e, null);
            if (f != null) println("created " + f.getName() + " @" + e + " size=" + f.getBody().getNumAddresses());
            else           println("FAILED to create fn @" + e);
        }
    }
}
