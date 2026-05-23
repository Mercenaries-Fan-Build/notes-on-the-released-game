// Export code/data references to the "VZ.WAD" string for PS3 EBOOT RE.
// Headless: analyzeHeadless ... -process EBOOT.elf -postScript ExportVzWadXrefs.java
// @category Mercenaries2

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.DataIterator;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.Listing;
import ghidra.program.model.mem.Memory;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceIterator;
import ghidra.program.model.symbol.ReferenceManager;

import java.io.FileWriter;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

public class ExportVzWadXrefs extends GhidraScript {

    private static final String TARGET = "VZ.WAD";
    private static final long FALLBACK_ADDR = 0x00DDAB78L;

    @Override
    public void run() throws Exception {
        Listing listing = currentProgram.getListing();
        ReferenceManager refMgr = currentProgram.getReferenceManager();
        FunctionManager funcMgr = currentProgram.getFunctionManager();

        List<Address> hits = new ArrayList<>();
        DataIterator dataIt = listing.getDefinedData(true);
        while (dataIt.hasNext()) {
            Data d = dataIt.next();
            if (d.hasStringValue() && TARGET.equals(d.getDefaultValueRepresentation())) {
                hits.add(d.getAddress());
            }
        }

        if (hits.isEmpty()) {
            Memory mem = currentProgram.getMemory();
            Address found = mem.findBytes(
                currentProgram.getMinAddress(),
                currentProgram.getMaxAddress(),
                TARGET.getBytes(),
                null,
                true,
                monitor);
            if (found != null) {
                hits.add(found);
                println("WARN: using memory search hit at " + found);
            } else {
                Address fallback = toAddr(FALLBACK_ADDR);
                if (fallback != null) {
                    hits.add(fallback);
                    println("WARN: using fallback " + fallback);
                }
            }
        }

        String outPath = System.getenv("GHIDRA_VZ_XREF_OUT");
        if (outPath == null || outPath.isEmpty()) {
            outPath = "analysis/cross_platform/ps3_eboot/ghidra_vz_wad_xrefs.txt";
        }

        try (PrintWriter pw = new PrintWriter(new FileWriter(outPath))) {
            pw.println("# VZ.WAD xrefs from " + currentProgram.getName());
            pw.println("# program: " + currentProgram.getExecutablePath());
            pw.println();

            for (Address strAddr : hits) {
                pw.println("STRING " + strAddr);
                ReferenceIterator refs = refMgr.getReferencesTo(strAddr);
                int n = 0;
                while (refs.hasNext()) {
                    Reference ref = refs.next();
                    Address from = ref.getFromAddress();
                    Function fn = funcMgr.getFunctionContaining(from);
                    String fnName = fn != null ? fn.getName() : "(no function)";
                    String fnAddr = fn != null ? fn.getEntryPoint().toString() : "-";
                    Instruction ins = listing.getInstructionAt(from);
                    String insStr = ins != null ? ins.toString() : "-";
                    pw.println(String.format(
                        "  REF from=%s type=%s fn=%s @%s | %s",
                        from, ref.getReferenceType(), fnName, fnAddr, insStr));
                    n++;
                }
                pw.println("  TOTAL_REFS " + n);
                pw.println();
            }

            // Also dump nearby string hits for WAD path patterns
            String[] patterns = {"%s\\%s.wad", "%s\\%s-patch.wad", "LOADING.WAD", "SHELL.WAD"};
            for (String pat : patterns) {
                DataIterator it2 = listing.getDefinedData(true);
                while (it2.hasNext()) {
                    Data d = it2.next();
                    if (!d.hasStringValue() || !pat.equals(d.getDefaultValueRepresentation())) {
                        continue;
                    }
                    pw.println("STRING " + pat + " @ " + d.getAddress());
                    ReferenceIterator refs = refMgr.getReferencesTo(d.getAddress());
                    int c = 0;
                    while (refs.hasNext()) {
                        Reference ref = refs.next();
                        Function fn = funcMgr.getFunctionContaining(ref.getFromAddress());
                        pw.println("  REF from=" + ref.getFromAddress()
                            + " fn=" + (fn != null ? fn.getName() + "@" + fn.getEntryPoint() : "?"));
                        c++;
                        if (c >= 20) {
                            pw.println("  ... truncated");
                            break;
                        }
                    }
                    pw.println("  TOTAL_REFS " + c);
                    pw.println();
                }
            }

            pw.println("# Static anchors (see analysis/cross_platform/ps3_eboot/ps3_eboot_re_targets.md)");
            pw.println("ANCHOR 0x00FC6380 filename_pointer_table");
            pw.println("ANCHOR 0x00FC63B4 VZ.WAD_slot -> 0x00DDAB78");
            pw.println("ANCHOR 0x00FB4D60 FxArchiveStoreFile_vtable");
            pw.println("ANCHOR 0x00DF06A8 FxArchiveStoreFile_typeinfo");
            pw.println("ANCHOR 0x00DB2A30 FxArchiveStoreFile_vmethod0_code");
        }

        println("Wrote " + outPath);
        println("Note: direct xrefs to VZ.WAD are often 0 on PPC64 (TOC). Use 0x00FC63B4 and FxArchive vtable.");
    }
}
