// preScript: create a function at every start address listed in <startsPath>.
// Args: <startsPath>  — one hex VA per line (no 0x prefix), e.g. the .pdata function starts of
// the image being imported. The list must belong to that image: the Xbox builds share no layout.
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import java.nio.file.*;
import java.util.List;

public class CreateFunctions extends GhidraScript {
    private static final String USAGE = "<startsPath>";

    // Script argument <index>; the script stops with the usage line when it is absent.
    private String requiredArg(int index) {
        String[] args = getScriptArgs();
        if (args.length <= index) {
            throw new IllegalArgumentException("missing script argument " + (index + 1)
                + "; usage: " + getClass().getSimpleName() + ".java " + USAGE);
        }
        return args[index];
    }

    public void run() throws Exception {
        String fp = requiredArg(0);
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
