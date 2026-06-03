#!/usr/bin/env python3
"""Capture an x32dbg process snapshot for patch-WAD bisection runs.

Read-only capture (no breakpoints, no thread switching). Pause the game in
x32dbg first, then run this script.

Output layout:
  output/_bisection_results/<variant_id>/<snapshot_id>/snapshot.json
  output/_bisection_results/<variant_id>/manifest.json  (updated each capture)

Snapshot IDs (standard before/after pair):
  main-menu   — game paused on the main menu (healthy baseline)
  load-broken — game paused after a failed VZ load attempt
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import requests

THIS_DIR = Path(__file__).resolve().parent
REPO = THIS_DIR.parent
DEFAULT_OUT = REPO / "output" / "_bisection_results"
DEFAULT_SERVER = "http://127.0.0.1:8888/"
BISect_MANIFEST = REPO / "output" / "data" / "bisect" / "manifest.json"  # optional metadata only

SNAPSHOT_IDS = ("main-menu", "load-broken")

# Known globals / anchors from live-debug sessions (Mercenaries2.exe @ 0x00400000).
WATCH_ADDRS: dict[str, str] = {
    "render_view_slot_0xDFC2F8": "0x00DFC2F8",
    "globalenter_stride_gate_0x1176078": "0x01176078",
}

WORKER_START = 0x876400
GLOBALENTER_LOOP = 0x4B1180


def _utc_iso() -> str:
    return datetime.now(UTC).isoformat()


def _api_get(server: str, endpoint: str, params: dict[str, str] | None = None) -> Any:
    url = f"{server.rstrip('/')}/{endpoint.lstrip('/')}"
    resp = requests.get(url, params=params or {}, timeout=20)
    resp.raise_for_status()
    try:
        return resp.json()
    except ValueError:
        return resp.text.strip()


def _parse_hex(s: str) -> int:
    return int(str(s).replace("0x", "").replace("0X", ""), 16)


def _hex_u32_words(raw: str, count: int = 8) -> list[str]:
    if not raw or not isinstance(raw, str):
        return []
    data = raw.replace(" ", "")
    words: list[str] = []
    for i in range(0, min(len(data), count * 8), 8):
        chunk = data[i : i + 8]
        if len(chunk) < 8:
            break
        val = int(chunk, 16)
        words.append(f"0x{val:08x}")
    return words


def _classify_state(threads: dict[str, Any], regs: dict[str, Any], active: bool) -> str:
    if not active:
        cip = _parse_hex(regs.get("cip", "0"))
        esi = _parse_hex(regs.get("csi", regs.get("esi", "0")))  # typo guard
        if "esi" in regs:
            esi = _parse_hex(regs["esi"])
        if cip != 0 and (cip < 0x00400000 or cip > 0x04000000) and cip < 0x20000000:
            if cip == esi or cip < 0x01000000:
                return "PAUSED_FAULT"
        return "PAUSED"

    main = None
    worker = None
    for t in threads.get("threads", []):
        sa = _parse_hex(t.get("startAddress", "0"))
        if t.get("threadName") == "Main Thread" or sa == 0:
            main = t
        if sa == WORKER_START:
            worker = t
    if main is None and threads.get("threads"):
        main = threads["threads"][0]
    if main and worker:
        mc = int(main.get("cycles", 0))
        wc = int(worker.get("cycles", 0))
        if mc > 100_000_000_000 and wc > 100_000_000_000:
            main_cip = _parse_hex(main.get("cip", "0"))
            if GLOBALENTER_LOOP <= main_cip <= GLOBALENTER_LOOP + 0x200:
                return "RUNNING_LIVELOCK"
            return "RUNNING_HOT"
    return "RUNNING"


def _load_wad_meta(variant_id: str) -> dict[str, Any] | None:
    if not BISect_MANIFEST.is_file():
        return None
    for entry in json.loads(BISect_MANIFEST.read_text(encoding="utf-8")):
        if entry.get("id") == variant_id:
            return entry
    return None


def capture_snapshot(
    *,
    server: str,
    variant_id: str,
    snapshot_id: str,
    note: str,
    out_root: Path,
) -> Path:
    if snapshot_id not in SNAPSHOT_IDS:
        raise ValueError(f"snapshot_id must be one of {SNAPSHOT_IDS}")

    is_debugging = _api_get(server, "IsDebugging")
    if not is_debugging:
        raise RuntimeError("x32dbg is not debugging a process")

    is_active = _api_get(server, "IsDebugActive")
    if is_active:
        raise RuntimeError(
            "Process is still running — pause in x32dbg first (F12), then re-run capture"
        )

    threads = _api_get(server, "GetThreadList")
    regs = _api_get(server, "GetRegisterDump")
    callstack = _api_get(server, "GetCallStack")

    state = _classify_state(threads, regs, bool(is_active))

    mem_windows: dict[str, Any] = {}
    for label, addr in WATCH_ADDRS.items():
        try:
            raw = _api_get(server, "Memory/Read", {"addr": addr, "size": "16"})
            mem_windows[label] = {
                "addr": addr,
                "hex": raw,
                "u32": _hex_u32_words(raw, 4),
            }
        except Exception as exc:  # noqa: BLE001
            mem_windows[label] = {"addr": addr, "error": str(exc)}

    esp = regs.get("csp", regs.get("esp", "0x0"))
    stack_raw = None
    stack_decoded: list[str] = []
    try:
        stack_raw = _api_get(server, "Memory/Read", {"addr": esp, "size": "64"})
        stack_decoded = _hex_u32_words(stack_raw, 16)
    except Exception:
        pass

    cip = regs.get("cip", "0x0")
    disasm = None
    try:
        disasm = _api_get(
            server,
            "DisasmGetInstructionRange",
            {"addr": cip, "count": "8"},
        )
    except Exception:
        pass

    cip_target: dict[str, Any] | None = None
    if state == "PAUSED_FAULT" or (
        cip and _parse_hex(cip) >= 0x01000000 and _parse_hex(cip) < 0x40000000
    ):
        try:
            target_raw = _api_get(server, "Memory/Read", {"addr": cip, "size": "32"})
            cip_target = {
                "addr": cip,
                "hex": target_raw,
                "u32": _hex_u32_words(target_raw, 8),
            }
        except Exception:
            pass

    # Compact thread summary (matches prior xdbg_monitor jsonl style).
    thread_rows = []
    main_info = None
    worker_info = None
    for t in threads.get("threads", []):
        row = {
            "t": t.get("threadId"),
            "c": t.get("cip"),
            "y": t.get("cycles"),
            "w": t.get("waitReason"),
            "sa": t.get("startAddress"),
        }
        thread_rows.append(row)
        sa = _parse_hex(t.get("startAddress", "0"))
        if t.get("threadName") == "Main Thread":
            main_info = {"tid": t.get("threadId"), "cip": t.get("cip"), "cycles": t.get("cycles")}
        if sa == WORKER_START:
            worker_info = {
                "tid": t.get("threadId"),
                "cip": t.get("cip"),
                "cycles": t.get("cycles"),
            }

    payload: dict[str, Any] = {
        "schema": "bisect_snapshot_v1",
        "variant_id": variant_id,
        "snapshot_id": snapshot_id,
        "iso_timestamp": _utc_iso(),
        "is_debugging": bool(is_debugging),
        "is_debug_active": bool(is_active),
        "state": state,
        "note": note,
        "regs": regs,
        "main": main_info,
        "worker_876400": worker_info,
        "threads": thread_rows,
        "callstack": callstack,
        "stack_esp": stack_decoded,
        "memory_windows": mem_windows,
        "disasm_at_cip": disasm,
        "cip_target": cip_target,
        "wad_variant": _load_wad_meta(variant_id),
    }

    out_dir = out_root / variant_id / snapshot_id
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "snapshot.json"
    out_file.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    variant_manifest_path = out_root / variant_id / "manifest.json"
    variant_manifest: dict[str, Any]
    if variant_manifest_path.is_file():
        variant_manifest = json.loads(variant_manifest_path.read_text(encoding="utf-8"))
    else:
        wad = _load_wad_meta(variant_id)
        variant_manifest = {
            "variant_id": variant_id,
            "description": (wad or {}).get("description", ""),
            "wad_file": (wad or {}).get("file", ""),
            "wad_sha256": (wad or {}).get("sha256", ""),
            "snapshots": {},
        }
    variant_manifest.setdefault("snapshots", {})[snapshot_id] = {
        "captured_at": payload["iso_timestamp"],
        "state": state,
        "path": str(out_file.relative_to(REPO)).replace("\\", "/"),
    }
    variant_manifest["updated_at"] = payload["iso_timestamp"]
    variant_manifest_path.write_text(
        json.dumps(variant_manifest, indent=2) + "\n", encoding="utf-8"
    )

    root_manifest_path = out_root / "manifest.json"
    root_manifest: dict[str, Any]
    if root_manifest_path.is_file():
        root_manifest = json.loads(root_manifest_path.read_text(encoding="utf-8"))
    else:
        root_manifest = {"variants": {}}
    root_manifest.setdefault("variants", {})[variant_id] = {
        "manifest": str(variant_manifest_path.relative_to(REPO)).replace("\\", "/"),
        "snapshots": list(variant_manifest.get("snapshots", {}).keys()),
    }
    root_manifest["updated_at"] = payload["iso_timestamp"]
    root_manifest_path.write_text(json.dumps(root_manifest, indent=2) + "\n", encoding="utf-8")

    return out_file


def main() -> int:
    ap = argparse.ArgumentParser(description="Capture x32dbg bisection snapshot")
    ap.add_argument("--variant", required=True, help="Bisect WAD variant id (e.g. step2-retest)")
    ap.add_argument(
        "--snapshot",
        required=True,
        choices=SNAPSHOT_IDS,
        help="Snapshot phase id: main-menu (before) or load-broken (after)",
    )
    ap.add_argument("--note", default="", help="Optional capture note")
    ap.add_argument("--out-root", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--server", default=os.getenv("X64DBG_URL", DEFAULT_SERVER))
    args = ap.parse_args()

    try:
        out = capture_snapshot(
            server=args.server,
            variant_id=args.variant,
            snapshot_id=args.snapshot,
            note=args.note,
            out_root=args.out_root.resolve(),
        )
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    print(f"Wrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
