Place optional OBJ / glTF / DDS samples here (paths like /models/foo.obj).

The dev server also scans ../output/review and ../output/extracted/review for stage-2 outputs — see repo README.

Skeletal animation GLBs from output/animations (mercs2_anim_pipeline) include animation clips. Each GLB carries a skeleton_status in asset.extras: "decoded" means a real skeleton was resolved from game data; "unknown" means only flat placeholder tracks exist (no bind pose, no skin, no mesh). When decoded, a rigid preview mesh may be embedded. "Retarget clips to separately loaded glTF" is reserved for future use. Use "Skeleton helper" when the export exposes THREE.Bone nodes.
