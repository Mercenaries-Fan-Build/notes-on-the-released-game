#!/usr/bin/env python3
"""Quick debugger state check via x32dbg MCP HTTP API."""
import requests
import sys

URL = "http://127.0.0.1:8888/"


def get(endpoint, params=None):
    r = requests.get(URL + endpoint, params=params or {}, timeout=10)
    try:
        return r.json()
    except Exception:
        return r.text


def main():
    regs = get("RegisterDump")
    if not isinstance(regs, dict):
        print(f"Could not get registers: {regs}")
        return

    eip = regs.get("cip", 0)
    eax = regs.get("cax", 0)
    ecx = regs.get("ccx", 0)
    status = regs.get("lastStatus", {})

    print(f"EIP: {eip}")
    print(f"EAX: {eax}")
    print(f"ECX: {ecx}")
    print(f"lastStatus: {status}")

    eip_int = int(eip, 16) if isinstance(eip, str) else eip
    if eip_int == 0x83664E:
        print("=> Same MixSources crash (0x83664E)")
    else:
        print(f"=> DIFFERENT location from MixSources crash!")

    # Disasm
    addr_str = eip if isinstance(eip, str) else hex(eip)
    dis = get("Disasm/GetInstructionRange", {"addr": addr_str, "count": "6"})
    print("\nDisassembly:")
    if isinstance(dis, list):
        for inst in dis:
            a = inst.get("address", "?")
            t = inst.get("instruction", "?")
            print(f"  {a}: {t}")

    # Call stack
    stack = get("GetCallStack")
    print("\nCall stack:")
    if isinstance(stack, dict):
        entries = stack.get("callstack", stack.get("entries", []))
        if isinstance(entries, list):
            for i, f in enumerate(entries[:10]):
                print(f"  [{i}] {f}")
        else:
            print(f"  {stack}")


if __name__ == "__main__":
    main()
