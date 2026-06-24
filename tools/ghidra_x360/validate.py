# Ghidra Jython — validate that the recovered Xbox PPC PE loads + disassembles.
# Prints language, image base, memory blocks, and disassembles at the first
# .pdata function (0x82170000) to confirm the language decodes real PPC.
prog = currentProgram
print("== VALIDATE ==")
print("LANG: %s" % prog.getLanguageID())
print("IMAGEBASE: %s" % prog.getImageBase())
print("BLOCKS:")
for b in prog.getMemory().getBlocks():
    print("  %-10s %s - %s  (%d bytes) x=%s" % (b.getName(), b.getStart(), b.getEnd(),
          b.getSize(), b.isExecute()))

from ghidra.app.cmd.disassemble import DisassembleCommand
af = prog.getAddressFactory()
addr = af.getAddress("0x82170000")
DisassembleCommand(addr, None, True).applyTo(prog)
listing = prog.getListing()
print("DISASM @0x82170000 (first .pdata function):")
a = addr
for i in range(16):
    ins = listing.getInstructionAt(a)
    if ins is None:
        print("  %s: (no instruction)" % a); break
    print("  %s: %s" % (a, ins))
    a = ins.getMaxAddress().add(1)
print("== END VALIDATE ==")
