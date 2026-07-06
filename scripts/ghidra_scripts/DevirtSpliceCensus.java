// Devirtualization phase 1 — census + reconstruction data for every .text -> SecuROM splice.
// SecuROM "stole" bytes from .text functions and replaced them with a jmp/call into a macro in
// Stext/.securom; the macro holds the original (relocated) bytes + a jmp back to .text. To DROP
// the SecuROM sections we must restore each stolen region into .text. This script enumerates all
// splice sites, follows each macro to its return-to-.text, captures the stolen bytes, and
// classifies recoverability:
//   A (recoverable)  : macro = <original bytes> ; jmp/ret back to .text, no dispatcher/anti-debug
//   A* (needs fixup) : as A but contains internal rel8/rel32 branches whose disp must be recomputed
//   C (protection)   : macro calls a dispatcher ([mem]) or contains anti-debug (push ss / int 2d / rdtsc)
//   B (unknown)      : no clean return-to-.text within the walk limit
// Output: output/_ghidra/devirt_splice_census.json  + printed summary counts.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.FlowType;
import ghidra.program.model.symbol.Reference;
import java.io.File;
import java.io.PrintWriter;
import java.util.Arrays;

public class DevirtSpliceCensus extends GhidraScript {
    private MemoryBlock textBlk;
    private MemoryBlock[] srBlks;
    private static final int MAX_MACRO_INSNS = 48;

    private boolean inText(Address a) { return a != null && textBlk.contains(a); }
    private boolean inSR(Address a) {
        if (a == null) return false;
        for (MemoryBlock b : srBlks) if (b.contains(a)) return true;
        return false;
    }

    private String hex(byte[] b) {
        StringBuilder sb = new StringBuilder();
        for (byte x : b) sb.append(String.format("%02x", x & 0xff));
        return sb.toString();
    }

    @Override
    public void run() throws Exception {
        textBlk = currentProgram.getMemory().getBlock(".text");
        String[] names = {"Stext", "Sitext", "Srdata", "Sdata", ".securom"};
        java.util.List<MemoryBlock> sr = new java.util.ArrayList<>();
        for (String n : names) { MemoryBlock b = currentProgram.getMemory().getBlock(n); if (b != null) sr.add(b); }
        srBlks = sr.toArray(new MemoryBlock[0]);

        File out = new File("C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\devirt_splice_census.json");
        PrintWriter pw = new PrintWriter(out, "UTF-8");
        pw.println("{\"sites\":[");

        long nA = 0, nAfix = 0, nC = 0, nB = 0, total = 0;
        boolean first = true;

        InstructionIterator it = currentProgram.getListing().getInstructions(textBlk.getStart(), true);
        while (it.hasNext()) {
            Instruction ins = it.next();
            if (!inText(ins.getMinAddress())) break;
            FlowType ft = ins.getFlowType();
            if (!(ft.isJump() || ft.isCall())) continue;
            // find a flow target that lands in an SR block
            Address target = null;
            for (Address f : ins.getFlows()) if (inSR(f)) { target = f; break; }
            if (target == null) {
                for (Reference r : ins.getReferencesFrom())
                    if ((r.getReferenceType().isJump() || r.getReferenceType().isCall()) && inSR(r.getToAddress()))
                        { target = r.getToAddress(); break; }
            }
            if (target == null) continue;

            total++;
            // walk the macro
            Address cur = target, retAddr = null;
            String cls = "B";
            boolean antiDebug = false, dispatcher = false, needFix = false;
            long stolenLen = 0;
            Address macroStart = target, macroEnd = target;
            for (int i = 0; i < MAX_MACRO_INSNS; i++) {
                Instruction m = getInstructionAt(cur);
                if (m == null) { break; }
                macroEnd = m.getMaxAddress();
                // anti-debug opcode sniff
                byte[] mb;
                try { mb = m.getBytes(); } catch (Exception e) { mb = new byte[0]; }
                if (mb.length >= 1 && (mb[0] == 0x16 || mb[0] == 0x17)) antiDebug = true;         // push/pop ss
                if (mb.length >= 2 && (mb[0] & 0xff) == 0xcd && (mb[1] & 0xff) == 0x2d) antiDebug = true; // int 2d
                if (mb.length >= 2 && (mb[0] & 0xff) == 0x0f && (mb[1] & 0xff) == 0x31) antiDebug = true; // rdtsc
                FlowType mft = m.getFlowType();
                // internal relative branch that needs disp fixup on relocation
                if ((mft.isJump() || mft.isConditional()) && mb.length <= 6) {
                    for (Address mf : m.getFlows()) if (mf != null && !inText(mf)) needFix = true;
                }
                if (mft.isCall()) {
                    // call into SR or call [mem] => dispatcher/protection
                    boolean toSR = false; for (Address mf : m.getFlows()) if (inSR(mf)) toSR = true;
                    if (toSR || m.getMnemonicString().toLowerCase().contains("call")) {
                        Address[] fl = m.getFlows();
                        if (fl.length == 0 || toSR) { dispatcher = true; }
                    }
                }
                // terminal: unconditional jump/return whose target is in .text
                if (mft.isTerminal() || (mft.isJump() && !mft.isConditional())) {
                    Address rt = null;
                    for (Address mf : m.getFlows()) if (inText(mf)) rt = mf;
                    if (rt != null) { retAddr = rt; stolenLen = m.getMinAddress().getOffset() - target.getOffset(); break; }
                    // jmp deeper into SR (chained macro) -> follow
                    if (mft.isJump() && !mft.isConditional()) {
                        Address nx = null; for (Address mf : m.getFlows()) if (inSR(mf)) nx = mf;
                        if (nx != null) { cur = nx; continue; }
                    }
                    if (mft.isTerminal()) { break; } // ret gadget w/o resolvable .text target
                }
                cur = m.getMaxAddress().add(1);
            }

            if (dispatcher || antiDebug) cls = "C";
            else if (retAddr != null) cls = needFix ? "A*" : "A";
            else cls = "B";

            switch (cls) { case "A": nA++; break; case "A*": nAfix++; break; case "C": nC++; break; default: nB++; }

            byte[] stolen = new byte[0];
            if (retAddr != null && stolenLen > 0 && stolenLen < 4096) {
                stolen = new byte[(int) stolenLen];
                try { currentProgram.getMemory().getBytes(target, stolen); } catch (Exception e) { stolen = new byte[0]; }
            }

            if (!first) pw.println(","); first = false;
            pw.print(String.format(
                "{\"site\":\"0x%08x\",\"siteInsn\":\"%s\",\"siteLen\":%d,\"target\":\"0x%08x\",\"class\":\"%s\","
                + "\"ret\":%s,\"stolenLen\":%d,\"antiDebug\":%b,\"dispatcher\":%b,\"needFix\":%b,\"stolen\":\"%s\"}",
                ins.getMinAddress().getOffset(), ins.toString().replace("\"","'"), ins.getLength(),
                target.getOffset(), cls,
                retAddr == null ? "null" : String.format("\"0x%08x\"", retAddr.getOffset()),
                stolenLen, antiDebug, dispatcher, needFix, hex(stolen)));
        }
        pw.println("\n],");
        pw.println(String.format("\"summary\":{\"total\":%d,\"A_recoverable\":%d,\"Astar_needfix\":%d,\"C_protection\":%d,\"B_unknown\":%d}}",
            total, nA, nAfix, nC, nB));
        pw.close();
        println(String.format("SPLICE CENSUS: total=%d  A=%d  A*=%d(needs disp fixup)  C=%d(protection)  B=%d(unknown)",
            total, nA, nAfix, nC, nB));
        println("wrote " + out.getAbsolutePath());
    }
}
