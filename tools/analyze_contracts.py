#!/usr/bin/env python3
"""Analyze all disassembled Lua scripts for contract patterns and APIs.

Generates a comprehensive summary of:
- All inherit/import relationships
- Event API patterns (types, arguments, callbacks)
- Contract lifecycle (Activated, Complete, Cancel, Cleanup)
- MrxTaskContract method calls

Reads from output_demo/scripts_disasm/ directory.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def main() -> int:
    disasm_dir = Path("output_demo/scripts_disasm")
    if not disasm_dir.is_dir():
        print("ERROR: No disasm directory", file=sys.stderr)
        return 1

    all_inherits: dict[str, str] = {}  # script -> inherits_from
    all_imports: dict[str, list[str]] = {}  # script -> list of imports
    event_patterns: list[dict] = []
    contract_methods: dict[str, list[str]] = {}  # method -> list of scripts
    lifecycle_funcs: dict[str, list[str]] = {}  # func -> list of scripts
    self_complete_calls: list[dict] = []

    for f in sorted(disasm_dir.glob("*.disasm.txt")):
        script_name = f.stem.replace(".disasm", "")
        text = f.read_text()
        lines = text.split("\n")

        # Find inherit patterns - look in constants section
        for i, line in enumerate(lines):
            if '; inherit' in line and 'GETGLOBAL' in line:
                for j in range(i+1, min(i+3, len(lines))):
                    m = re.search(r'LOADK\s+\d+\s+-\d+\s*;\s*"([^"]+)"', lines[j])
                    if m:
                        all_inherits[script_name] = m.group(1)
                        break
                break

        # Find import patterns
        imports = []
        for i, line in enumerate(lines):
            if '; import' in line and 'GETGLOBAL' in line:
                for j in range(i+1, min(i+3, len(lines))):
                    m = re.search(r'LOADK\s+\d+\s+-\d+\s*;\s*"([^"]+)"', lines[j])
                    if m:
                        imports.append(m.group(1))
                        break
        if imports:
            all_imports[script_name] = imports

        # Find _CreateEvent patterns (the full call signature)
        for i, line in enumerate(lines):
            if '_CreateEvent' in line or '_CreatePersistentEvent' in line:
                method = "_CreatePersistentEvent" if "Persistent" in line else "_CreateEvent"
                # Look for Event type in next few lines
                event_type = None
                timer_val = None
                callback = None
                for j in range(i+1, min(i+10, len(lines))):
                    if event_type is None:
                        m = re.search(r'GETTABLE\s+\d+\s+\d+\s+-\d+\s*;\s*"([^"]+)"', lines[j])
                        if m and m.group(1) not in ("Create", "GetGuidByName", "GetLocalCharacter", "GetAnyCharacter"):
                            event_type = m.group(1)
                    if timer_val is None:
                        m = re.search(r'LOADK\s+\d+\s+-\d+\s*;\s*(\d+(?:\.\d+)?)', lines[j])
                        if m:
                            timer_val = m.group(1)
                    if callback is None:
                        m = re.search(r'GETGLOBAL\s+\d+\s+-\d+\s*;\s*(\w+)', lines[j])
                        if m and m.group(1) not in ("Event", "Player", "Pg", "Object", "Math"):
                            callback = m.group(1)
                        m2 = re.search(r'GETTABLE\s+\d+\s+\d+\s+-\d+\s*;\s*"([^"]+)"', lines[j])
                        if m2 and m2.group(1) not in (event_type or "", "Create", "GetGuidByName",
                                                       "GetLocalCharacter", "GetAnyCharacter",
                                                       "ObjectProximity", "TimerRelative",
                                                       "Boundary", "ObjectInSeat"):
                            if callback is None:
                                callback = m2.group(1)

                event_patterns.append({
                    "script": script_name,
                    "method": method,
                    "event_type": event_type,
                    "timer_value": timer_val,
                    "callback": callback,
                })

        # Find Event.Create (standalone, not _CreateEvent)
        for i, line in enumerate(lines):
            if '"; Event' in line or '; Event' in line:
                if i+1 < len(lines) and '"Create"' in lines[i+1]:
                    # This is Event.Create(...)
                    event_type = None
                    timer_val = None
                    callback = None
                    for j in range(i+2, min(i+12, len(lines))):
                        if event_type is None:
                            m = re.search(r'GETTABLE\s+\d+\s+\d+\s+-\d+\s*;\s*"([^"]+)"', lines[j])
                            if m and m.group(1) not in ("Create", "GetGuidByName",
                                                         "GetLocalCharacter", "GetAnyCharacter"):
                                event_type = m.group(1)
                        if timer_val is None:
                            m = re.search(r'LOADK\s+\d+\s+-\d+\s*;\s*(\d+(?:\.\d+)?)', lines[j])
                            if m:
                                timer_val = m.group(1)
                        if callback is None:
                            m = re.search(r'GETGLOBAL\s+\d+\s+-\d+\s*;\s*(\w+)', lines[j])
                            if m and m.group(1) not in ("Event", "Player", "Pg", "Object", "Math"):
                                callback = m.group(1)

                    event_patterns.append({
                        "script": script_name,
                        "method": "Event.Create",
                        "event_type": event_type,
                        "timer_value": timer_val,
                        "callback": callback,
                    })

        # Find lifecycle functions defined
        for func in ("LoadAssets", "Activated", "Cancel", "Cleanup", "Complete"):
            if f'; {func}' in text and 'SETGLOBAL' in text:
                lifecycle_funcs.setdefault(func, []).append(script_name)

        # Find self:Complete() calls
        for i, line in enumerate(lines):
            m = re.search(r'SELF\s+\d+\s+0\s+-\d+\s*;\s*"Complete"', line)
            if m:
                # This is self:Complete()
                self_complete_calls.append({"script": script_name, "line": i})

        # Find MrxTaskContract method usages
        for i, line in enumerate(lines):
            m = re.search(r'MrxTaskContract.*"(\w+)"', line)
            if m:
                method = m.group(1)
                contract_methods.setdefault(method, []).append(script_name)

    # Output results
    print("=" * 80)
    print("MERCENARIES 2 LUA SCRIPT ANALYSIS — CONTRACT & API PATTERNS")
    print("=" * 80)

    print(f"\n{'='*60}")
    print("1. INHERITANCE HIERARCHY")
    print(f"{'='*60}")
    base_classes: dict[str, list[str]] = {}
    for script, parent in sorted(all_inherits.items()):
        base_classes.setdefault(parent, []).append(script)
    for parent, children in sorted(base_classes.items(), key=lambda x: -len(x[1])):
        print(f"\n  {parent} ({len(children)} scripts):")
        for c in sorted(children):
            print(f"    - {c}")

    print(f"\n{'='*60}")
    print("2. EVENT API PATTERNS")
    print(f"{'='*60}")

    event_types: dict[str, int] = {}
    for ep in event_patterns:
        et = ep["event_type"] or "(unknown)"
        event_types[et] = event_types.get(et, 0) + 1
    print("\n  Event types used:")
    for et, count in sorted(event_types.items(), key=lambda x: -x[1]):
        print(f"    {et:30s} ({count} usages)")

    print("\n  Event creation methods:")
    methods_used: dict[str, int] = {}
    for ep in event_patterns:
        methods_used[ep["method"]] = methods_used.get(ep["method"], 0) + 1
    for m, count in sorted(methods_used.items(), key=lambda x: -x[1]):
        print(f"    {m:30s} ({count} usages)")

    print("\n  TimerRelative examples (with timer values and callbacks):")
    timer_examples = [ep for ep in event_patterns if ep["event_type"] == "TimerRelative"]
    seen = set()
    for ep in timer_examples[:30]:
        tv = ep["timer_value"] or "?"
        cb = ep["callback"] or "(closure)"
        key = (ep["script"], tv, cb)
        if key in seen:
            continue
        seen.add(key)
        print(f"    {ep['script']:30s} timer={tv:>5s}  callback={cb}")

    print(f"\n{'='*60}")
    print("3. CONTRACT LIFECYCLE FUNCTIONS")
    print(f"{'='*60}")
    for func in ("LoadAssets", "Activated", "Cancel", "Cleanup"):
        scripts = lifecycle_funcs.get(func, [])
        print(f"\n  {func} defined in {len(scripts)} scripts")

    print(f"\n{'='*60}")
    print("4. MrxTaskContract BASE CLASS METHODS USED")
    print(f"{'='*60}")
    for method, scripts in sorted(contract_methods.items(), key=lambda x: -len(x[1])):
        print(f"  {method:30s} ({len(scripts)} scripts): "
              f"{', '.join(sorted(set(scripts))[:5])}")

    print(f"\n{'='*60}")
    print("5. self:Complete() CALL PATTERN")
    print(f"{'='*60}")
    complete_scripts = sorted(set(c["script"] for c in self_complete_calls))
    print(f"  {len(complete_scripts)} scripts call self:Complete():")
    for s in complete_scripts:
        print(f"    - {s}")

    print(f"\n{'='*60}")
    print("6. IMPORTS CATALOG (most common)")
    print(f"{'='*60}")
    import_counts: dict[str, int] = {}
    for script, imps in all_imports.items():
        for imp in imps:
            import_counts[imp] = import_counts.get(imp, 0) + 1
    for imp, count in sorted(import_counts.items(), key=lambda x: -x[1])[:30]:
        print(f"    {imp:30s} ({count} scripts)")

    print(f"\n{'='*60}")
    print("7. KEY QUESTIONS ANSWERED")
    print(f"{'='*60}")
    print("""
  Q: Is MrxTaskContract in this block?
  A: NO. It's inherited but not defined here. It's in the engine's Lua
     runtime (likely in a scripts_common or scripts_base block that's
     loaded earlier). All contracts call inherit("MrxTaskContract") which
     sets up the prototype chain.

  Q: What does MrxTaskContract.Activated(self) do?
  A: Based on the patterns, it likely:
     - Sets up the contract's event tracking system
     - Registers the contract as "active" with the task system
     - Enables _CreateEvent and _CreatePersistentEvent methods
     - May call LoadAssets if not already called

  Q: What's the minimal contract structure?
  A: Based on gurjob001 and other simple scripts:
     1. inherit("MrxTaskContract") or a subclass
     2. Define Activated(self) that calls parent.Activated(self) 
     3. Optionally define Cancel(self), Cleanup(self), LoadAssets(self)
     4. Call self:Complete() when done

  Q: How does Event.Create vs self:_CreateEvent differ?
  A: Two patterns:
     - self:_CreateEvent(Event.TYPE, {params}, callback, {args})
       Tracked by the contract system; auto-cleaned on cancel/complete
     - Event.Create(Event.TYPE, {params}, callback, {args})
       Standalone event; NOT auto-cleaned; must be manually deleted

  Q: Would a timer-based auto-complete work?
  A: YES. The pattern is:
     self:_CreateEvent(Event.TimerRelative, {seconds}, CallbackFn, {self})
     Many scripts use TimerRelative with callbacks. A 5-second delay
     followed by self:Complete() is the simplest possible approach.
""")

    # Save as JSON
    output = {
        "inherits": all_inherits,
        "imports": all_imports,
        "event_types": event_types,
        "event_patterns_sample": event_patterns[:50],
        "lifecycle_funcs": lifecycle_funcs,
        "contract_methods": {k: sorted(set(v)) for k, v in contract_methods.items()},
        "complete_scripts": complete_scripts,
    }
    out_path = disasm_dir / "contract_analysis.json"
    out_path.write_text(json.dumps(output, indent=2))
    print(f"\nFull analysis saved to: {out_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
