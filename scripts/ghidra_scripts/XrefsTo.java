// Report every reference (read/write/data) to a set of addresses, with the
// containing function and reference type. Used to find the writer of the version
// override globals (override A 0x017C0DF8, override B 0x01175C68) and the online-
// config block base 0x017C0BC0 in the SecuROM-unpacked image.
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.listing.Function;

public class XrefsTo extends GhidraScript {
    private static final long[] TARGETS = { 0x017C0DF8L, 0x01175C68L, 0x017C0BC0L, 0x017C0DE9L };
    @Override
    public void run() throws Exception {
        for (long t : TARGETS) {
            Address a = toAddr(t);
            println(String.format("=== refs to 0x%08x ===", t));
            int n = 0;
            for (Reference r : getReferencesTo(a)) {
                Function f = getFunctionContaining(r.getFromAddress());
                println(String.format("  %-8s from 0x%08x  %s",
                    r.getReferenceType().getName(),
                    r.getFromAddress().getOffset(),
                    f != null ? f.getName() : "(no fn)"));
                n++;
            }
            if (n == 0) println("  (no references recorded)");
        }
    }
}
