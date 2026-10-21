// Every reference into a function that starts in the SecuROM blocks, for working out which of
// those functions the game's code reaches.
//
// For each function whose entry lies in one of the named SecuROM blocks the script writes one row
// per reference to an address inside that function (its entry or its body), with where the
// reference comes from. A reference from inside an instruction gives that instruction's
// containing function; a reference from data gives the data address only.
//
// Args: <outPath> <reachOut> <codeBlock> <securomBlocks>
//   outPath        TSV of references written (must not exist)
//   reachOut       TSV of per-function reachability written (must not exist)
//   codeBlock      name of the game's code block, e.g. .text
//   securomBlocks  comma-separated SecuROM block names, e.g. Stext,Sitext,Srdata,Sdata,.securom
// Every named block must exist; anything else stops the script.
// Output columns: function (entry), function_block, to (referenced address), to_entry (yes | no),
// from (address), from_block (block name, or - outside memory), from_kind (instruction | data |
// other), from_function (entry of the function containing the source instruction, or -),
// ref_type (Ghidra's reference type).
// A function with no reference gets one row with from = -.
//
// reachOut gets one row per such function (columns function, function_block, reach), where reach
// is, in this order:
//   text            referenced by an instruction in the code block
//   text-chain      referenced by an instruction in a function that is itself text or text-chain
//   securom-only    referenced by instructions, none of them in the code block or a reached function
//   data-only       referenced only from data or from instructions outside any function
//   none            no references
// The last line printed is
// "SecuromFunctionRefs: <functions> functions, <rows> rows, reach <class>=<n>... in <program>".
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
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Deque;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

public class SecuromFunctionRefs extends GhidraScript {
    private static final String USAGE = "<outPath> <reachOut> <codeBlock> <securomBlocks>";

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
        File reachOut = new File(requiredArg(1));
        for (File f : new File[] {out, reachOut}) {
            if (f.exists()) throw new IllegalArgumentException("output already exists: " + f);
        }
        MemoryBlock code = block(requiredArg(2));
        List<MemoryBlock> sr = new ArrayList<>();
        for (String n : requiredArg(3).split(",")) sr.add(block(n));

        Map<Address, String> blockOf = new LinkedHashMap<>();
        Set<Address> fromText = new HashSet<>(), insnRef = new HashSet<>(), anyRef = new HashSet<>();
        Map<Address, Set<Address>> callers = new HashMap<>();

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
            Address fe = f.getEntryPoint();
            blockOf.put(fe, fb.getName());
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
                    anyRef.add(fe);
                    if (ins != null && code.contains(from)) {
                        fromText.add(fe);
                    } else if (ff != null && !ff.getEntryPoint().equals(fe)) {
                        insnRef.add(fe);
                        callers.computeIfAbsent(fe, k -> new HashSet<>()).add(ff.getEntryPoint());
                    }
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

        // text-chain: a function referenced by an instruction in a reached function.
        Map<Address, Set<Address>> callees = new HashMap<>();
        for (Map.Entry<Address, Set<Address>> e : callers.entrySet()) {
            for (Address c : e.getValue()) callees.computeIfAbsent(c, k -> new HashSet<>()).add(e.getKey());
        }
        Set<Address> reached = new HashSet<>(fromText);
        Deque<Address> work = new ArrayDeque<>(fromText);
        while (!work.isEmpty()) {
            for (Address n : callees.getOrDefault(work.poll(), Collections.emptySet())) {
                if (reached.add(n)) work.add(n);
            }
        }
        Map<String, Integer> counts = new TreeMap<>();
        PrintWriter rw = new PrintWriter(reachOut, "UTF-8");
        rw.println("function\tfunction_block\treach");
        for (Map.Entry<Address, String> e : blockOf.entrySet()) {
            Address f = e.getKey();
            String reach = fromText.contains(f) ? "text"
                : reached.contains(f) ? "text-chain"
                : insnRef.contains(f) ? "securom-only"
                : anyRef.contains(f) ? "data-only"
                : "none";
            counts.merge(reach, 1, Integer::sum);
            rw.println(hx(f) + "\t" + e.getValue() + "\t" + reach);
        }
        rw.close();
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, Integer> c : counts.entrySet()) sb.append(' ').append(c.getKey()).append('=').append(c.getValue());
        println("SecuromFunctionRefs: " + fns + " functions, " + rows + " rows, reach" + sb + " in "
            + currentProgram.getName());
    }
}
