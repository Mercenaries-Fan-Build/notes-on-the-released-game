from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

import requests


DEFAULT_SERVER_URL = "http://127.0.0.1:8888/"


def _parse_int(value: Any) -> int | None:
    if value is None:
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return None
        try:
            return int(text, 16) if text.lower().startswith("0x") else int(text, 10)
        except ValueError:
            return None
    return None


def _fmt_hex(value: int) -> str:
    return f"0x{value:08X}"


def _load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _http_get(server_url: str, endpoint: str, params: dict[str, Any] | None = None) -> Any:
    url = f"{server_url.rstrip('/')}/{endpoint.lstrip('/')}"
    response = requests.get(url, params=params or {}, timeout=15)
    response.raise_for_status()
    try:
        return response.json()
    except ValueError:
        return response.text.strip()


def _module_base_and_size(module_entry: dict[str, Any]) -> tuple[int | None, int | None]:
    base_candidates = ("base", "baseAddress", "modbase", "addr", "start")
    size_candidates = ("size", "moduleSize", "modsize")

    base = None
    size = None
    for key in base_candidates:
        base = _parse_int(module_entry.get(key))
        if base is not None:
            break
    for key in size_candidates:
        size = _parse_int(module_entry.get(key))
        if size is not None:
            break
    return base, size


def _module_name(module_entry: dict[str, Any]) -> str:
    for key in ("name", "module", "moduleName", "path", "file", "filename"):
        value = module_entry.get(key)
        if isinstance(value, str) and value.strip():
            return Path(value).name
    return ""


def _find_module(modules: list[dict[str, Any]], module_name: str) -> dict[str, Any] | None:
    target = module_name.lower()
    for entry in modules:
        name = _module_name(entry).lower()
        if name == target:
            return entry
    return None


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            chunk = f.read(1024 * 1024)
            if not chunk:
                break
            digest.update(chunk)
    return digest.hexdigest()


def resolve_pack(pack: dict[str, Any], server_url: str) -> dict[str, Any]:
    errors: list[str] = []
    warnings: list[str] = []

    exe = pack.get("exe", {})
    module_name = exe.get("module_name")
    exe_path = exe.get("path")
    exe_size = _parse_int(exe.get("size_bytes"))
    exe_sha = str(exe.get("sha256", "")).strip().lower()

    if not isinstance(module_name, str) or not module_name.strip():
        errors.append("exe.module_name is required")
    if not isinstance(exe_path, str) or not exe_path.strip():
        errors.append("exe.path is required")
    if exe_size is None or exe_size <= 0:
        errors.append("exe.size_bytes must be a positive integer")
    if not exe_sha or exe_sha == "replace_with_real_sha256":
        errors.append("exe.sha256 must be set to a real SHA-256 value")

    if errors:
        return {
            "ok": False,
            "errors": errors,
            "warnings": warnings,
            "resolved_probes": [],
        }

    exe_file = Path(exe_path)
    if not exe_file.exists():
        errors.append(f"exe.path does not exist on disk: {exe_file}")
    else:
        actual_size = exe_file.stat().st_size
        if actual_size != exe_size:
            errors.append(
                f"exe.size_bytes mismatch: pack={exe_size} actual={actual_size}"
            )
        actual_sha = _sha256_file(exe_file).lower()
        if actual_sha != exe_sha:
            errors.append(
                f"exe.sha256 mismatch: pack={exe_sha} actual={actual_sha}"
            )

    module_list = _http_get(server_url, "GetModuleList")
    if not isinstance(module_list, list):
        errors.append(f"GetModuleList did not return a list: {module_list!r}")
        return {
            "ok": False,
            "errors": errors,
            "warnings": warnings,
            "resolved_probes": [],
        }

    module_entry = _find_module(module_list, module_name)
    if module_entry is None:
        errors.append(f"module not found in debugger session: {module_name}")
        return {
            "ok": False,
            "errors": errors,
            "warnings": warnings,
            "resolved_probes": [],
        }

    module_base, module_size = _module_base_and_size(module_entry)
    if module_base is None:
        errors.append("module base could not be parsed from GetModuleList entry")
        return {
            "ok": False,
            "errors": errors,
            "warnings": warnings,
            "resolved_probes": [],
        }

    probe_results: list[dict[str, Any]] = []
    probes = pack.get("probes", [])
    if not isinstance(probes, list) or not probes:
        errors.append("pack.probes must be a non-empty array")
        return {
            "ok": False,
            "errors": errors,
            "warnings": warnings,
            "resolved_probes": [],
        }

    for probe in probes:
        probe_id = str(probe.get("probe_id", "")).strip()
        required = bool(probe.get("required", False))
        address = probe.get("address", {})

        if not probe_id:
            errors.append("probe with missing probe_id")
            continue

        if not isinstance(address, dict):
            errors.append(f"{probe_id}: address must be an object")
            continue

        rva = _parse_int(address.get("rva"))
        va = _parse_int(address.get("va"))

        derived_rva = None
        resolved_va = None
        resolved = True
        probe_errors: list[str] = []

        if rva is None and va is None:
            probe_errors.append("missing both address.rva and address.va")
            resolved = False
        elif rva is not None:
            resolved_va = module_base + rva
            if va is not None:
                expected_rva = va - module_base
                if expected_rva != rva:
                    probe_errors.append(
                        f"rva/va mismatch for current module base: rva={_fmt_hex(rva)} "
                        f"va={_fmt_hex(va)} base={_fmt_hex(module_base)}"
                    )
                    resolved = False
        else:
            if va is None:
                probe_errors.append("internal error: unresolved va path")
                resolved = False
            else:
                resolved_va = va
                derived_rva = va - module_base
                if derived_rva < 0:
                    probe_errors.append(
                        f"va below module base: va={_fmt_hex(va)} base={_fmt_hex(module_base)}"
                    )
                    resolved = False

        result = {
            "probe_id": probe_id,
            "required": required,
            "resolved": resolved,
            "module_base": _fmt_hex(module_base),
            "resolved_va": _fmt_hex(resolved_va) if resolved_va is not None else None,
            "rva": _fmt_hex(rva) if rva is not None else None,
            "derived_rva": _fmt_hex(derived_rva) if derived_rva is not None else None,
            "errors": probe_errors,
        }
        probe_results.append(result)
        if probe_errors:
            errors.extend([f"{probe_id}: {msg}" for msg in probe_errors])

    for result in probe_results:
        if result["required"] and not result["resolved"]:
            errors.append(f"{result['probe_id']}: required probe unresolved")

    return {
        "ok": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "server_url": server_url,
        "pack_id": pack.get("pack_id"),
        "module_name": module_name,
        "module_base": _fmt_hex(module_base),
        "module_size": _fmt_hex(module_size) if module_size is not None else None,
        "resolved_probes": probe_results,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Validate and resolve x32dbg address pack probes against live module base."
    )
    parser.add_argument("--pack", required=True, type=Path, help="Path to address pack JSON.")
    parser.add_argument("--out", type=Path, default=None, help="Optional output JSON path.")
    parser.add_argument(
        "--server-url",
        default=DEFAULT_SERVER_URL,
        help=f"x32dbg MCP HTTP endpoint base URL (default: {DEFAULT_SERVER_URL})",
    )
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    pack = _load_json(args.pack)
    report = resolve_pack(pack, args.server_url)
    if args.out is not None:
        _write_json(args.out, report)
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if report.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
