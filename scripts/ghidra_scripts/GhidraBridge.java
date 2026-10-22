// A long-lived query/edit server over one open program, for tools that ask many questions of an
// image without paying for a headless start per question (tools/corpus_mcp/src/ghidra_bridge.js
// starts one per image).
//
// Run as the only postScript of a headless session on a saved project opened writable
// (-process <program> -noanalysis). It listens on a Unix-domain socket, serves one client
// connection at a time (a closed connection returns to accept), and returns when a client sends
// the `shutdown` request; the headless run then saves the program as usual.
//
// Args: <socketPath> <imageId> <ordinalTable> <imports|-> <editsLedger>
//   socketPath    the socket file to create (must not exist)
//   imageId       the mercs2_exemap images.tsv id of the program (reported by `info`)
//   ordinalTable, imports   as FnMnemonicSig.java's; they feed the call lists (CallList.java)
//   editsLedger   TSV every edit is appended to (created with its header when missing):
//                 time, image_id, op, va, old, new, reason
//
// Protocol: one JSON object per line each way. Request {"id":<n>,"op":<name>,...params};
// response {"id":<n>,"ok":true,"result":...} or {"id":<n>,"ok":false,"error":"<message>"}.
// Addresses are "0x%08x" strings. Ops:
//   info                                → image_id, program, program_sha256, language, image_base,
//                                         functions, writable
//   function {va}                       → the function containing va: entry, name, name_source,
//                                         signature, size, body [[start,end]...], thunk,
//                                         thunk_target, callers [{site,function}], callees (the
//                                         call-list grammar of FnMnemonicSig.java)
//   decompile {va}                      → entry, name, c (null on failure), error (null on success)
//   disassemble {va, count?}            → [{va, bytes, text}]: the containing function's body in
//                                         address order, or `count` instructions from va (≤ 4000)
//   xrefs_to {va}                       → [{from, type, function}] every reference to va
//   strings {regex, limit?}             → [{va, value, functions}] defined strings matching the Java
//                                         regex (find), each with the functions referencing it
//                                         (limit ≤ 2000, default 200; `truncated` says more matched)
//   read_bytes {va, length}             → hex (length ≤ 65536)
//   rename_function {va, name, reason}  → old, new: renames the function whose entry is va
//   set_comment {va, kind, text, reason} → old, new: kind pre|post|eol|plate|repeatable
//   shutdown                            → stops serving
// An edit needs a non-empty reason, is written to the ledger, then committed and saved before the
// response (end(true); DomainFile.save; start()). A program that cannot be saved (opened -readOnly)
// refuses edits. Any other request shape is an error response naming what is wrong; an exception
// while serving is an error response, not the end of the server.
// @category Mercs2
import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonNull;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressRange;
import ghidra.program.model.listing.CodeUnit;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.DataIterator;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.listing.Listing;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.SourceType;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.Writer;
import java.net.StandardProtocolFamily;
import java.net.UnixDomainSocketAddress;
import java.nio.channels.Channels;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

public class GhidraBridge extends GhidraScript {
    private static final String USAGE = "<socketPath> <imageId> <ordinalTable> <imports|-> <editsLedger>";
    private static final int DECOMPILE_TIMEOUT_SECS = 120;
    private static final int MAX_DISASSEMBLY = 4000;
    private static final int MAX_BYTES = 65536;
    private static final int MAX_STRINGS = 2000;

    private final Gson gson = new Gson();
    private String imageId;
    private File ledger;
    private CallList callList;
    private DecompInterface decomp;

    private static final class BadRequest extends Exception {
        BadRequest(String msg) { super(msg); }
    }

    private String requiredArg(int index) {
        String[] args = getScriptArgs();
        if (args.length != 5) {
            throw new IllegalArgumentException("expected 5 script arguments, got " + args.length
                + "; usage: " + getClass().getSimpleName() + ".java " + USAGE);
        }
        return args[index];
    }

    @Override
    public void run() throws Exception {
        Path socket = Path.of(requiredArg(0));
        imageId = requiredArg(1);
        callList = new CallList(this, requiredArg(2), requiredArg(3));
        ledger = new File(requiredArg(4));
        if (Files.exists(socket)) throw new IllegalArgumentException("socket already exists: " + socket);
        decomp = new DecompInterface();
        if (!decomp.openProgram(currentProgram)) {
            throw new IllegalStateException("the decompiler cannot open " + currentProgram.getName() + ": " + decomp.getLastMessage());
        }
        try (ServerSocketChannel server = ServerSocketChannel.open(StandardProtocolFamily.UNIX)) {
            server.bind(UnixDomainSocketAddress.of(socket));
            println("GhidraBridge: listening on " + socket + " for " + imageId + " (" + currentProgram.getName() + ")");
            boolean stop = false;
            while (!stop) {
                try (SocketChannel client = server.accept()) {
                    stop = serve(client);
                }
            }
        } finally {
            decomp.dispose();
            Files.deleteIfExists(socket);
        }
        println("GhidraBridge: stopped");
    }

    // Serve one connection; true when a shutdown request ended it.
    private boolean serve(SocketChannel client) throws Exception {
        BufferedReader in = new BufferedReader(new InputStreamReader(Channels.newInputStream(client), StandardCharsets.UTF_8));
        Writer out = new OutputStreamWriter(Channels.newOutputStream(client), StandardCharsets.UTF_8);
        String line;
        while ((line = in.readLine()) != null) {
            JsonObject resp = new JsonObject();
            boolean stop = false;
            JsonElement id = JsonNull.INSTANCE;
            try {
                JsonObject req;
                try {
                    req = JsonParser.parseString(line).getAsJsonObject();
                } catch (Exception e) {
                    throw new BadRequest("request is not a JSON object: " + e.getMessage());
                }
                if (!req.has("id")) throw new BadRequest("request has no id");
                id = req.get("id");
                String op = str(req, "op");
                if ("shutdown".equals(op)) {
                    stop = true;
                    resp.add("result", new JsonObject());
                } else {
                    resp.add("result", dispatch(op, req));
                }
                resp.addProperty("ok", true);
            } catch (Exception e) {
                resp.addProperty("ok", false);
                resp.addProperty("error", e instanceof BadRequest ? e.getMessage() : e.toString());
            }
            resp.add("id", id);
            out.write(gson.toJson(resp));
            out.write('\n');
            out.flush();
            if (stop) return true;
        }
        return false;
    }

    private JsonElement dispatch(String op, JsonObject req) throws Exception {
        switch (op) {
            case "info": return info();
            case "function": return function(containing(addr(req, "va")));
            case "decompile": return decompile(containing(addr(req, "va")));
            case "disassemble": return disassemble(req);
            case "xrefs_to": return xrefsTo(addr(req, "va"));
            case "strings": return strings(req);
            case "read_bytes": return readBytes(req);
            case "rename_function": return renameFunction(req);
            case "set_comment": return setComment(req);
            default: throw new BadRequest("unknown op '" + op + "'");
        }
    }

    // --- request fields ------------------------------------------------------------------------

    private static String str(JsonObject req, String key) throws BadRequest {
        JsonElement e = req.get(key);
        if (e == null || !e.isJsonPrimitive() || !e.getAsJsonPrimitive().isString() || e.getAsString().isEmpty()) {
            throw new BadRequest("'" + key + "' must be a non-empty string");
        }
        return e.getAsString();
    }

    private static int intField(JsonObject req, String key, int dflt, int max) throws BadRequest {
        JsonElement e = req.get(key);
        if (e == null) return dflt;
        int v;
        try {
            v = e.getAsInt();
        } catch (Exception ex) {
            throw new BadRequest("'" + key + "' must be an integer");
        }
        if (v < 1 || v > max) throw new BadRequest("'" + key + "' must be between 1 and " + max);
        return v;
    }

    private Address addr(JsonObject req, String key) throws BadRequest {
        String s = str(req, key);
        if (!s.matches("0x[0-9a-fA-F]{1,16}")) throw new BadRequest("'" + key + "' is not a 0x-prefixed hex address: " + s);
        Address a = toAddr(Long.parseUnsignedLong(s.substring(2), 16));
        if (a == null || !currentProgram.getMemory().contains(a)) throw new BadRequest(s + " is not in the program's memory");
        return a;
    }

    private Function containing(Address a) throws BadRequest {
        Function f = getFunctionContaining(a);
        if (f == null) throw new BadRequest(hex(a) + " is in no function");
        return f;
    }

    private static String hex(Address a) {
        return String.format("0x%08x", a.getOffset());
    }

    // --- queries -------------------------------------------------------------------------------

    private JsonObject info() {
        JsonObject o = new JsonObject();
        o.addProperty("image_id", imageId);
        o.addProperty("program", currentProgram.getName());
        o.addProperty("program_sha256", currentProgram.getExecutableSHA256());
        o.addProperty("language", currentProgram.getLanguageID().getIdAsString());
        o.addProperty("image_base", hex(currentProgram.getImageBase()));
        o.addProperty("functions", currentProgram.getFunctionManager().getFunctionCount());
        o.addProperty("writable", currentProgram.getDomainFile().canSave());
        return o;
    }

    private JsonObject function(Function f) throws Exception {
        JsonObject o = new JsonObject();
        o.addProperty("entry", hex(f.getEntryPoint()));
        o.addProperty("name", f.getName(true));
        o.addProperty("name_source", f.getSymbol().getSource().toString());
        o.addProperty("signature", f.getSignature().getPrototypeString());
        o.addProperty("size", f.getBody().getNumAddresses());
        JsonArray body = new JsonArray();
        for (AddressRange r : f.getBody()) {
            JsonArray pair = new JsonArray();
            pair.add(hex(r.getMinAddress()));
            pair.add(hex(r.getMaxAddress()));
            body.add(pair);
        }
        o.add("body", body);
        o.addProperty("thunk", f.isThunk());
        if (f.isThunk()) o.addProperty("thunk_target", callList.thunkTarget(f));
        else o.add("thunk_target", JsonNull.INSTANCE);
        JsonArray callers = new JsonArray();
        for (Reference r : getReferencesTo(f.getEntryPoint())) {
            if (!r.getReferenceType().isCall()) continue;
            JsonObject c = new JsonObject();
            c.addProperty("site", hex(r.getFromAddress()));
            Function cf = getFunctionContaining(r.getFromAddress());
            if (cf == null) c.add("function", JsonNull.INSTANCE);
            else c.addProperty("function", hex(cf.getEntryPoint()));
            callers.add(c);
        }
        o.add("callers", callers);
        List<String> callees = new ArrayList<>();
        InstructionIterator it = currentProgram.getListing().getInstructions(f.getBody(), true);
        while (it.hasNext()) callList.addCallees(it.next(), f, callees);
        JsonArray ca = new JsonArray();
        for (String c : callees) ca.add(c);
        o.add("callees", ca);
        return o;
    }

    private JsonObject decompile(Function f) {
        JsonObject o = new JsonObject();
        o.addProperty("entry", hex(f.getEntryPoint()));
        o.addProperty("name", f.getName(true));
        DecompileResults r = decomp.decompileFunction(f, DECOMPILE_TIMEOUT_SECS, monitor);
        if (r != null && r.decompileCompleted()) {
            o.addProperty("c", r.getDecompiledFunction().getC());
            o.add("error", JsonNull.INSTANCE);
        } else {
            o.add("c", JsonNull.INSTANCE);
            o.addProperty("error", r == null ? "the decompiler returned nothing" : r.getErrorMessage());
        }
        return o;
    }

    private JsonArray disassemble(JsonObject req) throws Exception {
        Address a = addr(req, "va");
        Listing listing = currentProgram.getListing();
        JsonArray out = new JsonArray();
        if (req.has("count")) {
            int count = intField(req, "count", 0, MAX_DISASSEMBLY);
            Instruction ins = listing.getInstructionAt(a);
            if (ins == null) throw new BadRequest(hex(a) + " is not the start of an instruction");
            for (int i = 0; i < count && ins != null; i++, ins = ins.getNext()) out.add(instruction(ins));
            return out;
        }
        Function f = containing(a);
        InstructionIterator it = listing.getInstructions(f.getBody(), true);
        int n = 0;
        while (it.hasNext()) {
            if (++n > MAX_DISASSEMBLY) throw new BadRequest(f.getName() + " has more than " + MAX_DISASSEMBLY + " instructions; pass va and count");
            out.add(instruction(it.next()));
        }
        return out;
    }

    private JsonObject instruction(Instruction ins) throws Exception {
        JsonObject o = new JsonObject();
        o.addProperty("va", hex(ins.getAddress()));
        o.addProperty("bytes", CallList.hex(ins.getBytes()));
        o.addProperty("text", ins.toString());
        return o;
    }

    private JsonArray xrefsTo(Address a) {
        JsonArray out = new JsonArray();
        for (Reference r : getReferencesTo(a)) {
            JsonObject o = new JsonObject();
            o.addProperty("from", hex(r.getFromAddress()));
            o.addProperty("type", r.getReferenceType().getName());
            Function f = getFunctionContaining(r.getFromAddress());
            if (f == null) o.add("function", JsonNull.INSTANCE);
            else o.addProperty("function", hex(f.getEntryPoint()));
            out.add(o);
        }
        return out;
    }

    private JsonObject strings(JsonObject req) throws Exception {
        Pattern p;
        try {
            p = Pattern.compile(str(req, "regex"));
        } catch (java.util.regex.PatternSyntaxException e) {
            throw new BadRequest("regex does not compile: " + e.getDescription());
        }
        int limit = intField(req, "limit", 200, MAX_STRINGS);
        JsonArray hits = new JsonArray();
        boolean truncated = false;
        DataIterator it = currentProgram.getListing().getDefinedData(true);
        while (it.hasNext()) {
            Data d = it.next();
            if (!d.hasStringValue()) continue;
            String value = d.getDefaultValueRepresentation();
            Object v = d.getValue();
            if (v instanceof String) value = (String) v;
            if (!p.matcher(value).find()) continue;
            if (hits.size() == limit) {
                truncated = true;
                break;
            }
            JsonObject o = new JsonObject();
            o.addProperty("va", hex(d.getAddress()));
            o.addProperty("value", value);
            JsonArray fns = new JsonArray();
            for (Reference r : getReferencesTo(d.getAddress())) {
                Function f = getFunctionContaining(r.getFromAddress());
                if (f != null) fns.add(hex(f.getEntryPoint()));
            }
            o.add("functions", fns);
            hits.add(o);
        }
        JsonObject out = new JsonObject();
        out.add("strings", hits);
        out.addProperty("truncated", truncated);
        return out;
    }

    private JsonObject readBytes(JsonObject req) throws Exception {
        Address a = addr(req, "va");
        int length = intField(req, "length", 0, MAX_BYTES);
        byte[] b = new byte[length];
        int got = currentProgram.getMemory().getBytes(a, b);
        if (got != length) throw new BadRequest("only " + got + " of " + length + " bytes are readable at " + hex(a));
        JsonObject o = new JsonObject();
        o.addProperty("va", hex(a));
        o.addProperty("hex", CallList.hex(b));
        return o;
    }

    // --- edits ---------------------------------------------------------------------------------

    private void requireWritable() throws BadRequest {
        if (!currentProgram.getDomainFile().canSave()) {
            throw new BadRequest(currentProgram.getName() + " is opened read-only; edits are refused");
        }
    }

    // Append the edit to the ledger, then commit the script's transaction and save the program.
    private void commit(String op, Address a, String oldValue, String newValue, String reason) throws Exception {
        boolean header = !ledger.exists();
        if (ledger.getParentFile() != null) ledger.getParentFile().mkdirs();
        try (PrintWriter w = new PrintWriter(new FileWriter(ledger, StandardCharsets.UTF_8, true))) {
            if (header) w.println("time\timage_id\top\tva\told\tnew\treason");
            w.println(String.join("\t", Instant.now().toString(), imageId, op, hex(a), tsv(oldValue), tsv(newValue), tsv(reason)));
            if (w.checkError()) throw new IllegalStateException("writing " + ledger + " failed");
        }
        end(true);
        try {
            currentProgram.getDomainFile().save(monitor);
        } finally {
            start();
        }
    }

    private static String tsv(String s) {
        return s == null ? "-" : s.replace('\t', ' ').replace('\n', ' ').replace('\r', ' ');
    }

    private JsonObject renameFunction(JsonObject req) throws Exception {
        requireWritable();
        Address a = addr(req, "va");
        String name = str(req, "name");
        String reason = str(req, "reason");
        Function f = getFunctionAt(a);
        if (f == null) throw new BadRequest(hex(a) + " is not a function entry");
        String old = f.getName(true);
        f.setName(name, SourceType.USER_DEFINED);
        commit("rename_function", a, old, f.getName(true), reason);
        JsonObject o = new JsonObject();
        o.addProperty("old", old);
        o.addProperty("new", f.getName(true));
        return o;
    }

    private JsonObject setComment(JsonObject req) throws Exception {
        requireWritable();
        Address a = addr(req, "va");
        String kind = str(req, "kind");
        String text = str(req, "text");
        String reason = str(req, "reason");
        int type;
        switch (kind) {
            case "pre": type = CodeUnit.PRE_COMMENT; break;
            case "post": type = CodeUnit.POST_COMMENT; break;
            case "eol": type = CodeUnit.EOL_COMMENT; break;
            case "plate": type = CodeUnit.PLATE_COMMENT; break;
            case "repeatable": type = CodeUnit.REPEATABLE_COMMENT; break;
            default: throw new BadRequest("kind must be pre, post, eol, plate or repeatable, not '" + kind + "'");
        }
        Listing listing = currentProgram.getListing();
        if (listing.getCodeUnitAt(a) == null) throw new BadRequest(hex(a) + " is not the start of a code unit");
        String old = listing.getComment(type, a);
        listing.setComment(a, type, text);
        commit("set_comment:" + kind, a, old, text, reason);
        JsonObject o = new JsonObject();
        if (old == null) o.add("old", JsonNull.INSTANCE);
        else o.addProperty("old", old);
        o.addProperty("new", text);
        return o;
    }
}
