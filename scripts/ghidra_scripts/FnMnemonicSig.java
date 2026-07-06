// Per-function content signature for cross-build (v1.0 vs v1.1) diffing. The 1.1 patch moved
// functions to new addresses, so a byte/address diff is meaningless. Instead signature each
// .text function by its instruction-MNEMONIC sequence (invariant to addresses/immediates) plus
// its size and instruction count. Same code moved => identical mnemonic-sig; a patched function
// => changed sig. Run once per program (-process <name>) and diff the two JSONs offline.
//
// Output: output/_ghidra/fnsig_<programName>.json  => { "0xADDR": {"sig":"<hex sha>","n":<insns>,"sz":<bytes>,"calls":<int>} }
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.mem.MemoryBlock;
import java.io.File;
import java.io.PrintWriter;
import java.security.MessageDigest;

public class FnMnemonicSig extends GhidraScript {
    @Override
    public void run() throws Exception {
        MemoryBlock text = currentProgram.getMemory().getBlock(".text");
        long lo = text.getStart().getOffset(), hi = text.getEnd().getOffset();
        String prog = currentProgram.getName().replaceAll("[^A-Za-z0-9._-]", "_");
        File out = new File("C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\fnsig_" + prog + ".json");
        PrintWriter pw = new PrintWriter(out, "UTF-8");
        pw.println("{");
        MessageDigest md = MessageDigest.getInstance("SHA-1");
        boolean first = true;
        int nfn = 0;
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            long a = f.getEntryPoint().getOffset();
            if (a < lo || a > hi || f.isThunk()) continue;
            StringBuilder mn = new StringBuilder();
            int n = 0, calls = 0;
            Instruction ins = getInstructionAt(f.getEntryPoint());
            // walk the function body in address order
            ins = currentProgram.getListing().getInstructionAt(f.getEntryPoint());
            java.util.Iterator<Instruction> it = currentProgram.getListing().getInstructions(f.getBody(), true).iterator();
            while (it.hasNext()) {
                Instruction m = it.next();
                mn.append(m.getMnemonicString()).append(';');
                n++;
                if (m.getFlowType().isCall()) calls++;
            }
            md.reset();
            byte[] dig = md.digest(mn.toString().getBytes("UTF-8"));
            StringBuilder sig = new StringBuilder();
            for (int i = 0; i < 8; i++) sig.append(String.format("%02x", dig[i] & 0xff)); // 8-byte prefix
            if (!first) pw.println(","); first = false;
            pw.print(String.format("\"0x%08x\":{\"sig\":\"%s\",\"n\":%d,\"sz\":%d,\"calls\":%d}",
                a, sig.toString(), n, f.getBody().getNumAddresses(), calls));
            nfn++;
        }
        pw.println("\n}");
        pw.close();
        println("FnMnemonicSig: " + nfn + " .text functions -> " + out.getAbsolutePath());
    }
}
