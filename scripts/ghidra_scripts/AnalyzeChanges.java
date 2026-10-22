// Auto-analyse what earlier scripts of this run changed (GhidraScript.analyzeChanges): the
// addresses they disassembled or turned into functions, not the whole program. Run after
// CreateFunctions.java (or any script that adds code) on a saved program opened writable; the
// headless run saves the program.
// Args: none.
// @category Mercs2
import ghidra.app.script.GhidraScript;

public class AnalyzeChanges extends GhidraScript {
    @Override
    public void run() throws Exception {
        if (getScriptArgs().length != 0) {
            throw new IllegalArgumentException("AnalyzeChanges.java takes no arguments");
        }
        long t0 = System.currentTimeMillis();
        // The analysis manager learns of changes from the program's change events; deliver the
        // pending ones before asking it to analyse.
        currentProgram.flushEvents();
        analyzeChanges(currentProgram);
        println("AnalyzeChanges: analysed the changed addresses of " + currentProgram.getName() + " in "
            + ((System.currentTimeMillis() - t0) / 1000) + "s");
    }
}
