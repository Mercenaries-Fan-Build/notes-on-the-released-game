# High-value naming targets — aim external data (Mercs1 ODF, reflection-field values, XSI skeleton) HERE

52 UNNAMED nodes each shared across >=30 vehicle models. Cracking one name resolves it across
all those models. Guessing is exhausted (reflection-vocab, PC-WAD literal extraction, and exhaustive
GPU [a-z_] sweeps all returned zero). These need a data source that spells the studio-internal token.

| n_models | hash | stem-state (peeled) | classes | parent | example pos |
|---|---|---|---|---|---|
| 173 | 0x5D27E761 | 0x14BADB91 | boat | slice1a_pristine | (+0.0,+0.6,+14.3) |
| 172 | 0x765CD254 | 0xE141A8F6 | apc,boat,car,helicopter,motorcycle,plane,tank,truck | bone_frame | (+0.0,+0.0,+0.0) |
| 172 | 0x75F1F74D | 0x531D2FB5 | apc,boat,car,helicopter,motorcycle,plane,tank,truck | 0x765CD254 | (+0.0,+0.0,+0.0) |
| 172 | 0x255EAB53 | 0x5B67C76B | apc,boat,car,helicopter,motorcycle,plane,tank,truck | 0x765CD254 | (+0.0,+0.0,+0.0) |
| 119 | 0xFE1F4EA3 | 0xD82BE89B | apc,car,motorcycle,tank,truck | 0x255EAB53 | (-0.7,+1.0,+2.1) |
| 112 | 0x4119F5A8 | 0xCA585C92 | apc,car,motorcycle,tank,truck | 0x255EAB53 | (-1.0,+0.9,-4.0) |
| 112 | 0x2C3EDC3C | 0x1D1F487E | apc,boat,car,helicopter,motorcycle,plane,tank,truck | 0x75F1F74D | (+1.4,+2.6,-6.5) |
| 110 | 0x8BC21F85 | 0xECF469AD | apc,car,tank,truck | 0x255EAB53 | (+0.7,+1.0,+2.1) |
| 103 | 0x98B76A82 | 0x0090049C | apc,car,tank,truck | 0x255EAB53 | (+1.0,+0.9,-4.0) |
| 101 | 0xFA92EE23 | 0x1A8B7B1B | apc,car,tank,truck | 0x255EAB53 | (-0.7,+0.9,-4.0) |
| 101 | 0xD871B369 | 0x517B84B9 | apc,car,tank,truck | 0x255EAB53 | (+0.7,+0.9,-4.0) |
| 99 | 0xA641DAE1 | 0x1E1F4A11 | apc,boat,car,helicopter,motorcycle,plane,tank,truck | 0x75F1F74D | (+0.0,+3.7,-2.7) |
| 84 | 0x063C61D3 | 0x1C1F46EB | apc,boat,car,helicopter,motorcycle,plane,tank,truck | 0x75F1F74D | (-1.5,+2.7,-5.0) |
| 81 | 0x962C4871 | 0x39E9E041 | car,helicopter,truck | 0x715F5613 | (+1.0,+1.5,+2.0) |
| 81 | 0x715F5613 | 0x5A2A29AB | car,truck | 0x255EAB53 | (+0.0,+0.0,+0.0) |
| 81 | 0x3DF5A3EF | 0x23E9BD9F | car,helicopter,truck | 0x715F5613 | (-1.0,+1.5,+2.0) |
| 77 | 0xDB205EF6 | 0x11BAD6D8 | boat | slice1b_pristine | (+0.1,-0.0,-17.9) |
| 75 | 0xDD2E46E2 | 0x3190F2FC | car,truck | 0x962C4871 | (+1.0,+1.5,+2.0) |
| 75 | 0xA529917E | 0xC9988F60 | car,truck | 0x3DF5A3EF | (-1.0,+1.5,+2.0) |
| 75 | 0x913633E4 | 0x2489FB26 | car,truck | 0x962C4871 | (+1.0,+1.5,+2.0) |
| 75 | 0x4205CFD0 | 0x377812DA | car,truck | 0x3DF5A3EF | (-1.0,+1.5,+2.0) |
| 72 | 0xD14291B9 | 0x7BBF5F29 | car,truck | 0x715F5613 | (+0.0,+0.7,+2.2) |
| 72 | 0x89EA902A | 0x5AE87144 | car,truck | 0xD14291B9 | (+0.0,+0.4,+1.7) |
| 72 | 0x0CA1E5DC | 0x45249C1E | car,truck | 0xD14291B9 | (+0.0,+0.4,+1.7) |
| 64 | 0xFA23E154 | 0xAEC3BDF6 | car,truck | 0x2CE53661 | (+0.0,+2.0,+1.6) |
| 64 | 0x2FD85212 | 0x2ABE78CC | car,truck | 0x2CE53661 | (+0.0,+2.0,+1.6) |
| 64 | 0x2CE53661 | 0x4955B091 | car,truck | 0x715F5613 | (+0.0,+2.0,+1.6) |
| 61 | 0x243A5276 | 0x1B1F4558 | apc,boat,helicopter,plane,tank,truck | 0x75F1F74D | (+1.5,+2.6,-4.9) |
| 60 | 0xA40B15D4 | 0x75B28776 | car,truck | 0xFA23E154 | (+0.0,+0.9,+2.1) |
| 55 | 0xC88A3631 | 0x4CEFD381 | boat,car,plane,truck | 0x75F1F74D | (+0.0,+0.8,+0.5) |
| 52 | 0xC3290D88 | 0x78535172 | car,truck | 0x592552BD | (+0.0,+0.5,-1.8) |
| 52 | 0x592552BD | 0x6FBF4C45 | car,truck | 0x715F5613 | (+0.0,+0.8,-4.0) |
| 52 | 0x14D8F03E | 0x7AF1EDA0 | car,truck | 0x592552BD | (+0.0,+0.8,-4.1) |
| 38 | 0xABD9AD8F | 0x3D0A11BF | car,truck | 0x73A31898 | (+0.7,+0.5,+0.9) |
| 38 | 0x73A31898 | 0xCAE84422 | car,truck | 0x255EAB53 | (+0.7,+0.5,+0.9) |
| 38 | 0x423D5BE1 | 0xF9AA6511 | car,truck | 0x73A31898 | (+0.7,+0.5,+0.9) |
| 37 | 0xB581D08F | 0x132342BF | car,truck | 0x9380B8B6 | (-0.7,+0.5,+0.9) |
| 37 | 0x9380B8B6 | 0xBCE82E18 | car,truck | 0x255EAB53 | (-0.7,+0.5,+0.9) |
| 37 | 0x0D85F419 | 0xB12D6F09 | car,truck | 0x9380B8B6 | (-0.7,+0.5,+0.9) |
| 36 | 0xB164A5B3 | 0x2C07DF4B | car,helicopter,truck | 0x715F5613 | (-1.1,+2.2,-4.1) |
| 35 | 0xD98776ED | 0x3A07F555 | car,helicopter,truck | 0x715F5613 | (+1.1,+2.2,-4.1) |
| 33 | 0xFF7065C9 | 0x27930499 | car,truck | 0x255EAB53 | (+0.0,+0.0,+0.1) |
| 33 | 0x70B6D66B | 0x9FDC3EE3 | apc,boat,car,truck | 0x75F1F74D | (+0.0,+0.8,+1.2) |
| 33 | 0x5615C7EC | 0x981ABBCE | car,truck | 0xFF7065C9 | (+0.0,+0.0,+0.1) |
| 33 | 0x130F3AFA | 0x483B1D74 | car,truck | 0xFF7065C9 | (+0.0,+0.0,+0.1) |
| 32 | 0xBA39E05B | 0xAF170333 | apc,tank | 0x75F1F74D | (-0.6,+1.5,-0.1) |
| 31 | 0xA0858BA4 | 0xB5E31C66 | car,truck | 0xB164A5B3 | (-1.1,+2.2,-4.1) |
| 31 | 0x4001D72E | 0xE44D80F0 | car,truck | 0xD98776ED | (+1.1,+2.2,-4.1) |
| 31 | 0x2AE33DB8 | 0x081B3E42 | car,truck | 0xD98776ED | (+1.1,+2.2,-4.1) |
| 31 | 0x08C73C5A | 0xA5817254 | car,truck | 0xB164A5B3 | (-1.1,+2.2,-4.1) |
| 30 | 0x96E38F39 | 0xE18EDBA9 | apc,tank | 0x75F1F74D | (+0.0,+0.0,+0.0) |
| 30 | 0x2E4BAB55 | 0x221F505D | apc,boat,car,helicopter,plane,truck | 0x75F1F74D | (-1.0,+3.4,-6.6) |

## The three known-role subsystems (highest priority)

1. **Universal vehicle destruction group** (0x765CD254 / _pristine 0x255EAB53 / _ruin 0x75F1F74D),
   125 vehicles. STEM/_pristine/_ruin, shared stem-state 0xE141A8F6. >=12 chars or non-[a-z0-9_].
2. **Glass/window destruction cluster** (parent bone_glass__br_pristine): ~14 nodes at windshield/
   rear/side positions, mirror-paired, pristine+damaged, 72-119 vehicles each.
3. **Rotor system** (bone_rotor/bone_tailrotor are NAMED anchors): hub 0x8F96690F, blade series
   stem-state 0xB16B92D5 (bare hash 0x4B58676D), shared across 15 helicopters. bone_bluron/bluroff
   already cracked via the RotorBlurOn/OffBone reflection fields.

## Reflection fields whose VALUES are these bone names (from animation-skeleton.md):
RotorHubBoneName, FirstRotorBladeBoneName, ControlledWheelBone, ControlledSuspensionBone, SuspBone,
SuspensionStartBone, LookAtBone, VisPosBone, VisRotBone, VisYawBone, VisRudderBone, WinchBone,
DoorBoneName, ControlledBone, SrcBone/DestBone, StartBone/EndBone. Their string VALUES = the answers.