// preScript: create a function at every .pdata-derived start address.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import java.nio.file.*;
import java.util.List;

public class CreateFunctions extends GhidraScript {
    public void run() throws Exception {
        String fp = "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra_x360\\func_starts.txt";
        List<String> lines = Files.readAllLines(Paths.get(fp));
        int dis = 0, created = 0, n = 0;
        for (String line : lines) {
            line = line.trim();
            if (line.isEmpty()) continue;
            Address a = toAddr(Long.parseLong(line, 16));
            if (getInstructionAt(a) == null) { disassemble(a); dis++; }
            if (getFunctionAt(a) == null) {
                if (createFunction(a, null) != null) created++;
            }
            if ((++n % 5000) == 0) println("  ...processed " + n + " (dis=" + dis + " created=" + created + ")");
        }
        println("CreateFunctions: " + n + " starts, disassembled " + dis + ", created " + created + " functions");
    }
}
