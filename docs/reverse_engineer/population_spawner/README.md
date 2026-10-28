# Population simple-spawner — decoded specification (PC v1.0)

Function-level specifications of the retail runtime spawner, decoded 2026-10-21 from the PC v1.0
disassembly (`game-files/memory-dumps/*/image.bin`, the `updated-chris-exports` captures with their
SecuROM slots resolved) and cross-checked against the Xbox 360 preview / retail and PS3 builds. Every
line cites its address and carries a grade (PROVEN / INFERRED / SPECULATIVE, or P / I / S).

The runtime layout, the lifecycle summary and the unit-choice rules are in
[`../population_spawner_code_map.md`](../population_spawner_code_map.md) §6 / §6.1.

| File | Covers |
|---|---|
| [`activation_and_adjust.txt`](activation_and_adjust.txt) | SpawnerAdjust record + Lua keys, `TweakAttachedSpawners(InGroup)`, owner-goes-live activation (pending list, readiness, record walkers, activators), deactivate-all, cache-out, template inheritance (Transform `Parent`) |
| [`shared_helpers.txt`](shared_helpers.txt) | random draws, frame order, throttle, cycle countdown, skip / deactivate rolls, dormant check, health score, unit-slot checks, active-radius test, spawn transform, wakeup, on-spawn, Window ramp, releases, result plumbing |
| [`window_family.txt`](window_family.txt) | Window creator + updater, window entity, seat, arrival slide |
| [`nomodel_family.md`](nomodel_family.md) | NoModel creator + updater, ParkingSpace (SpawnerType 6) |
| [`hardpoint_family.md`](hardpoint_family.md) | Hardpoint creator + updater, node-health key, `FindTransforms`, seat key |
| [`path_family.txt`](path_family.txt) | Path creator + updater, path evaluation, Path object layout |
| [`anchors.md`](anchors.md) | The camera-eye and player-position arrays the active-range test measures from |

Owner health (RuntimeHealth / RuntimeNodeHealth) is created at entity activation:
[`../entity_health_activation.md`](../entity_health_activation.md).

Evidence files the specs cite (`scratchpad/…`) were session-local and are not kept; every claim is
re-derivable from the cited addresses.
