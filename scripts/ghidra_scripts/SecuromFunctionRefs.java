// Every reference into a function that starts in the SecuROM blocks, for working out which of
// those functions the game's code reaches.
//
// For each function whose entry lies in one of the named SecuROM blocks the script writes one row
// per reference to an address inside that function (its entry or its body), with where the
// reference comes from. A reference from inside an instruction gives that instruction's
// containing function; a reference from data gives the data address only.
//
// Args: <outPath> <codeBlock> <securomBlocks>
//   outPath        TSV written (must not exist)
//   codeBlock      name of the game's code block, e.g. .text
//   securomBlocks  comma-separated SecuROM block names, e.g. Stext,Sitext,Srdata,Sdata,.securom
// Every named block must exist; anything else stops the script.
// Output columns: function (entry), function_block, to (referenced address), to_entry (yes | no),
// from (address), from_block (block name, or - outside memory), from_kind (instruction | data |
// other), from_function (entry of the function containing the source instruction, or -),
// ref_type (Ghidra's reference type).
// A function with no reference gets one row with from = -. The last line printed is
// "SecuromFunctionRefs: <functions> functions, <rows> rows in <program>".
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressIterator;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceIterator;
import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

public class SecuromFunctionRefs extends GhidraScript {
    private static final String USAGE = "<outPath> <codeBlock> <securomBlocks>";

    private String requiredArg(int index) {
        String[] args = getScriptArgs();
        if (args.length <= index) {
            throw new IllegalArgumentException("missing script argument " + (index + 1)
                + "; usage: " + getClass().getSimpleName() + ".java " + USAGE);
        }
        return args[index];
    }

    private MemoryBlock block(String name) {
        MemoryBlock b = currentProgram.getMemory().getBlock(name);
        if (b == null) {
            throw new IllegalArgumentException("no memory block named '" + name + "' in " + currentProgram.getName());
        }
        return b;
    }

    private static String hx(Address a) {
        return String.format("0x%08x", a.getOffset());
    }

    @Override
    public void run() throws Exception {
        File out = new File(requiredArg(0));
        if (out.exists()) {
            throw new IllegalArgumentException("output already exists: " + out);
        }
        block(requiredArg(1));
        List<MemoryBlock> sr = new ArrayList<>();
        for (String n : requiredArg(2).split(",")) sr.add(block(n));

        PrintWriter pw = new PrintWriter(out, "UTF-8");
        pw.println("function\tfunction_block\tto\tto_entry\tfrom\tfrom_block\tfrom_kind\tfrom_function\tref_type");
        int fns = 0, rows = 0;
        FunctionIterator it = currentProgram.getFunctionManager().getFunctions(true);
        while (it.hasNext()) {
            Function f = it.next();
            MemoryBlock fb = null;
            for (MemoryBlock b : sr) if (b.contains(f.getEntryPoint())) fb = b;
            if (fb == null) continue;
            fns++;
            int before = rows;
            AddressIterator ai = currentProgram.getReferenceManager().getReferenceDestinationIterator(f.getBody(), true);
            while (ai.hasNext()) {
                Address to = ai.next();
                ReferenceIterator ri = currentProgram.getReferenceManager().getReferencesTo(to);
                while (ri.hasNext()) {
                    Reference r = ri.next();
                    Address from = r.getFromAddress();
                    MemoryBlock src = currentProgram.getMemory().getBlock(from);
                    Instruction ins = getInstructionContaining(from);
                    String kind = ins != null ? "instruction" : (getDataContaining(from) != null ? "data" : "other");
                    Function ff = ins != null ? getFunctionContaining(from) : null;
                    pw.println(hx(f.getEntryPoint()) + "\t" + fb.getName() + "\t" + hx(to) + "\t"
                        + (to.equals(f.getEntryPoint()) ? "yes" : "no") + "\t" + hx(from) + "\t"
                        + (src == null ? "-" : src.getName()) + "\t" + kind + "\t"
                        + (ff == null ? "-" : hx(ff.getEntryPoint())) + "\t" + r.getReferenceType().getName());
                    rows++;
                }
            }
            if (rows == before) {
                pw.println(hx(f.getEntryPoint()) + "\t" + fb.getName() + "\t-\t-\t-\t-\t-\t-\t-");
                rows++;
            }
        }
        pw.close();
        println("SecuromFunctionRefs: " + fns + " functions, " + rows + " rows in " + currentProgram.getName());
    }
}
