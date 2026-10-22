// Enable or disable one auto-analyzer in the program's analysis options, and make the analysis
// manager re-read its options (it caches each analyzer's enablement, and schedules an analyzer's
// work as code is defined — so disable an analyzer before the scripts that change code, e.g. as a
// preScript, and set it back as the last postScript).
// Args: <analyzer name> <true|false>
//   e.g. "Non-Returning Functions - Discovered" false. An analyzer the program's analysis options
//   do not have, or a value other than true/false, stops the script. Prints the previous and the
//   new setting.
// @category Mercs2
import ghidra.app.plugin.core.analysis.AutoAnalysisManager;
import ghidra.app.script.GhidraScript;
import ghidra.framework.options.Options;
import ghidra.program.model.listing.Program;

public class SetAnalyzerEnabled extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length != 2 || !("true".equals(args[1]) || "false".equals(args[1]))) {
            throw new IllegalArgumentException("usage: SetAnalyzerEnabled.java <analyzer name> <true|false>");
        }
        String name = args[0];
        Options opts = currentProgram.getOptions(Program.ANALYSIS_PROPERTIES);
        if (!opts.contains(name)) {
            throw new IllegalArgumentException("analysis options have no analyzer '" + name + "'");
        }
        boolean was = opts.getBoolean(name, true);
        boolean now = Boolean.parseBoolean(args[1]);
        opts.setBoolean(name, now);
        AutoAnalysisManager.getAnalysisManager(currentProgram).initializeOptions();
        println("SetAnalyzerEnabled: '" + name + "' " + was + " -> " + now + " in " + currentProgram.getName());
    }
}
