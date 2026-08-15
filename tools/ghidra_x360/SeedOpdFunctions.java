// preScript/postScript: seed functions from the PS3 .opd function-descriptor table.
// PS3 PPU 32-bit ABI: each 8-byte .opd entry is {u32 code, u32 toc}; the first
// word is the real code entry point. Section names are stripped from the EBOOT,
// so Ghidra never auto-identifies .opd -> pass its (start,size) as script args.
//
// IMPORTANT: seeds are disassembled in ONE bulk DisassembleCommand. Calling the
// flat-API disassemble() per address is super-linear (it re-walks a growing
// register-context AddressRangeMapDB) and takes hours on ~40k entries.
//
// args: <opdStartHex> <opdSizeHex> [analyze]
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSet;
import ghidra.program.model.lang.Register;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.ProgramContext;
import ghidra.program.model.mem.*;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import java.math.BigInteger;
import java.util.*;

public class SeedOpdFunctions extends GhidraScript {
    public void run() throws Exception {
        String[] args = getScriptArgs();
        long opdStart = Long.decode(args[0]);
        long opdSize  = Long.decode(args[1]);
        long tocR2 = (args.length > 2 && args[2].startsWith("0x")) ? Long.decode(args[2]) : 0;
        boolean doAnalyze = false, targetsOnly = false;
        for (String a : args) {
            if (a.equalsIgnoreCase("analyze")) doAnalyze = true;
            if (a.equalsIgnoreCase("targetsonly")) targetsOnly = true;
        }
        Memory mem = currentProgram.getMemory();

        long exLo = Long.MAX_VALUE, exHi = 0;
        for (MemoryBlock b : mem.getBlocks()) {
            if (b.isExecute()) {
                exLo = Math.min(exLo, b.getStart().getOffset());
                exHi = Math.max(exHi, b.getEnd().getOffset());
            }
        }
        println("SeedOpd: exec " + Long.toHexString(exLo) + ".." + Long.toHexString(exHi)
                + " opd " + Long.toHexString(opdStart) + " size " + Long.toHexString(opdSize)
                + " tocR2=" + Long.toHexString(tocR2) + " analyze=" + doAnalyze);

        // Paint r2 = TOC base as one range over each exec block BEFORE disassembly.
        // PS3 code is TOC-relative via r2; a single global value keeps the register
        // value map tiny (fast context lookups) and lets the decompiler resolve
        // TOC-relative globals.
        if (tocR2 != 0) {
            Register r2 = currentProgram.getRegister("r2");
            ProgramContext pc = currentProgram.getProgramContext();
            if (r2 != null) {
                BigInteger val = BigInteger.valueOf(tocR2);
                for (MemoryBlock b : mem.getBlocks()) {
                    if (b.isExecute()) {
                        try { pc.setValue(r2, b.getStart(), b.getEnd(), val); }
                        catch (Exception e) { println("  r2 paint failed on " + b.getName() + ": " + e); }
                    }
                }
                println("SeedOpd: painted r2=" + Long.toHexString(tocR2) + " over exec blocks");
            }
        }

        if (!targetsOnly) {
            // Collect code entry points from .opd.
            ArrayList<Address> entries = new ArrayList<>();
            AddressSet toDis = new AddressSet();
            for (long off = 0; off + 8 <= opdSize; off += 8) {
                if (monitor.isCancelled()) break;
                int code;
                try { code = mem.getInt(toAddr(opdStart + off)); }
                catch (MemoryAccessException e) { break; }
                long ca = code & 0xffffffffL;
                if (ca < exLo || ca > exHi) continue;
                Address ea = toAddr(ca);
                entries.add(ea);
                if (getInstructionAt(ea) == null) toDis.add(ea);
            }
            println("SeedOpd: opd code entries=" + entries.size() + " needing disasm=" + toDis.getNumAddresses());

            // ONE bulk disassemble over all seeds (fast; shared context).
            if (!toDis.isEmpty()) {
                DisassembleCommand cmd = new DisassembleCommand(toDis, null, true);
                cmd.applyTo(currentProgram, monitor);
                println("SeedOpd: bulk disassemble done");
            }

            int made = 0, bad = 0, n = 0;
            for (Address ea : entries) {
                if (monitor.isCancelled()) break;
                if (getFunctionAt(ea) == null) {
                    try { if (createFunction(ea, null) != null) made++; } catch (Exception e) { bad++; }
                }
                if ((++n % 5000) == 0) println("  createFunction " + n + "/" + entries.size() + " made=" + made);
            }
            println("SeedOpd: functionsCreated=" + made + " failed=" + bad);
        }

        // Guarantee the DLC-support targets exist (patch addrs; harmless on disc).
        long[] tg = {
            0x00522108L, 0x00522c38L, 0x005300f8L, 0x005370b8L, 0x005379a8L,
            0x00537ba0L, 0x00537d98L, 0x00550b50L, 0x00554b30L,
            0x002acc08L, 0x003225d8L, 0x000bd630L, 0x008d8d88L,
            0x00503ab0L, 0x00504a88L, 0x000107a8L, 0x001c18e0L, 0x001c15a8L
        };
        for (long t : tg) {
            Address ea = toAddr(t);
            if (getInstructionAt(ea) == null) {
                DisassembleCommand c = new DisassembleCommand(ea, null, true);
                c.applyTo(currentProgram, monitor);
            }
            if (getFunctionAt(ea) == null) {
                try { createFunction(ea, null); } catch (Exception e) { }
            }
            Function fn = getFunctionAt(ea);
            println("  target " + ea + " -> " + (fn != null ? fn.getName() : "STILL MISSING"));
        }

        if (doAnalyze) {
            println("SeedOpd: running incremental analysis...");
            analyzeChanges(currentProgram);
            println("SeedOpd: incremental analysis complete.");
        }
    }
}
