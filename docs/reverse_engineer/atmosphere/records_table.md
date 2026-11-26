| rec off | field | type | night (rgn_atmo_carmonaislandrain) | default (rgn_atmo_carmonaislandrain) | default (0x900000CF, live dump) |
|---|---|---|---|---|---|
| +0x000 | Name | u32 | 0xBB74C311 rgba(17,195,116,187) ['night'] | 0xBA71C11C rgba(28,193,113,186) default | 0xBA71C11C rgba(28,193,113,186) |
| +0x004 | InterpolateTime | f32 | 20 | 20 | 20 |
| +0x008 | LightMultiplier_X | f32 | 0.85 | 1 | 1 |
| +0x00c | LightMultiplier_Y | f32 | 0.8 | 0.925 | 1 |
| +0x010 | LightMultiplier_Z | f32 | 1 | 0.85 | 1 |
| +0x014 | LightMultiplier_W | f32 | 1 | 1 | 1 |
| +0x018 | LightIntensity | f32 | 0.55 | 0.75 | 1.15 |
| +0x01c | LightTime | f32 | 0.1 | 0.1 | 0.2 |
| +0x020 | LightTimeSpeed | f32 | 0 | 0 | 0 |
| +0x024 | SunEmissiveColor_X | f32 | 0.10674 | 0.16489 | 0.06 |
| +0x028 | SunEmissiveColor_Y | f32 | 0.11236 | 0.16489 | 0.06 |
| +0x02c | SunEmissiveColor_Z | f32 | 0.11236 | 0.10638 | 0.06 |
| +0x030 | SunEmissiveColor_W | f32 | 1 | 1 | 1 |
| +0x034 | AmbientColor | u32 | 0xFFC4A29D rgba(157,162,196,255) | 0xFFA37E81 rgba(129,126,163,255) | 0xFFA99583 rgba(131,149,169,255) |
| +0x038 | AmbientColorMultiplier | f32 | 1 | 1 | 1 |
| +0x03c | AmbientCube0 | u32 | 0x80969696 rgba(150,150,150,128) | 0x80756D68 rgba(104,109,117,128) | 0x8076625F rgba(95,98,118,128) |
| +0x040 | AmbientCube0Multiplier | f32 | 1 | 1 | 1 |
| +0x044 | AmbientCube1 | u32 | 0x80757575 rgba(117,117,117,128) | 0x8098816D rgba(109,129,152,128) | 0x8070675F rgba(95,103,112,128) |
| +0x048 | AmbientCube1Multiplier | f32 | 1 | 1 | 1 |
| +0x04c | AmbientCube2 | u32 | 0x80909090 rgba(144,144,144,128) | 0x80928583 rgba(131,133,146,128) | 0x80B0ACA4 rgba(164,172,176,128) |
| +0x050 | AmbientCube2Multiplier | f32 | 1 | 1 | 1 |
| +0x054 | AmbientCube3 | u32 | 0x804D4D4D rgba(77,77,77,128) | 0x804D4137 rgba(55,65,77,128) | 0x8049423A rgba(58,66,73,128) |
| +0x058 | AmbientCube3Multiplier | f32 | 1 | 1 | 1 |
| +0x05c | AmbientCube4 | u32 | 0x806A6A6A rgba(106,106,106,128) | 0x80756960 rgba(96,105,117,128) | 0x80747063 rgba(99,112,116,128) |
| +0x060 | AmbientCube4Multiplier | f32 | 1 | 1 | 1 |
| +0x064 | AmbientCube5 | u32 | 0x806B6B6B rgba(107,107,107,128) | 0x80877361 rgba(97,115,135,128) | 0x80837A67 rgba(103,122,131,128) |
| +0x068 | AmbientCube5Multiplier | f32 | 1 | 1 | 1 |
| +0x06c | RimColor | u32 | 0xFF5E4B2D rgba(45,75,94,255) | 0xFF2E333D rgba(61,51,46,255) | 0xFF464E53 rgba(83,78,70,255) |
| +0x070 | RimColorMultiplier | f32 | 1.12 | 1.1212 | 1.1212 |
| +0x074 | ScatterHGg | f32 | 0.50725 | 0.70513 | 0.80503 |
| +0x078 | ScatterTurbinity | f32 | 0 | 0 | 0 |
| +0x07c | ScatterInscatteringMultiplier | f32 | 5 | 5 | 15 |
| +0x080 | ScatterExtinctionMultiplier | f32 | 1 | 1 | 1 |
| +0x084 | ScatterBetaRayMultiplier | f32 | 0.0438 | 0.08 | 0.08319 |
| +0x088 | ScatterBetaMieMultiplier | f32 | 0.01 | 0.01 | 0.01 |
| +0x08c | AtmosphereLimit | f32 | 1000 | 1005.59 | 1083.33 |
| +0x090 | AtmosphereForce | f32 | 2 | 2 | 1 |
| +0x094 | HazeLimit | f32 | 85 | 85 | 85 |
| +0x098 | HazeForce | f32 | 0.5 | 0.5 | 0.5 |
| +0x09c | Water0_Index1 | i32 | 0 | 0 | 0 |
| +0x0a0 | Water0_Index2 | i32 | 85 | 85 | 85 |
| +0x0a4 | Water0_Color1 | u32 | 0x00333224 rgba(36,50,51,0) | 0x000F0F0F rgba(15,15,15,0) | 0x00000000 rgba(0,0,0,0) |
| +0x0a8 | Water0_Color2 | u32 | 0x5543372E rgba(46,55,67,85) | 0x55374031 rgba(49,64,55,85) | 0x55344130 rgba(48,65,52,85) |
| +0x0ac | Water1_Index1 | i32 | 85 | 85 | 85 |
| +0x0b0 | Water1_Index2 | i32 | 170 | 170 | 170 |
| +0x0b4 | Water1_Color1 | u32 | 0x5543372E rgba(46,55,67,85) | 0x55374031 rgba(49,64,55,85) | 0x55344130 rgba(48,65,52,85) |
| +0x0b8 | Water1_Color2 | u32 | 0xAA3E322F rgba(47,50,62,170) | 0xAA2C3425 rgba(37,52,44,170) | 0xAA253427 rgba(39,52,37,170) |
| +0x0bc | Water2_Index1 | i32 | 170 | 170 | 170 |
| +0x0c0 | Water2_Index2 | i32 | 255 | 255 | 255 |
| +0x0c4 | Water2_Color1 | u32 | 0xAA3E322F rgba(47,50,62,170) | 0xAA2C3425 rgba(37,52,44,170) | 0xAA253427 rgba(39,52,37,170) |
| +0x0c8 | Water2_Color2 | u32 | 0xFF62473E rgba(62,71,98,255) | 0xFF1B1E15 rgba(21,30,27,255) | 0xFF161D17 rgba(23,29,22,255) |
| +0x0cc | Gradient0_Index1 | i32 | 0 | 0 | 0 |
| +0x0d0 | Gradient0_Index2 | i32 | 128 | 128 | 128 |
| +0x0d4 | Gradient0_Color1 | u32 | 0x5C000000 rgba(0,0,0,92) | 0x4E000000 rgba(0,0,0,78) | 0x40000000 rgba(0,0,0,64) |
| +0x0d8 | Gradient0_Color2 | u32 | 0x5CC76038 rgba(56,96,199,92) | 0x4E72778D rgba(141,119,114,78) | 0x40798086 rgba(134,128,121,64) |
| +0x0dc | Gradient1_Index1 | i32 | 128 | 128 | 128 |
| +0x0e0 | Gradient1_Index2 | i32 | 255 | 255 | 255 |
| +0x0e4 | Gradient1_Color1 | u32 | 0x5CC76038 rgba(56,96,199,92) | 0x4E72778D rgba(141,119,114,78) | 0x40798086 rgba(134,128,121,64) |
| +0x0e8 | Gradient1_Color2 | u32 | 0x5CFFFFFF rgba(255,255,255,92) | 0x4EFFFFFF rgba(255,255,255,78) | 0x40FFFFFF rgba(255,255,255,64) |
| +0x0ec | Gradient2_Index1 | i32 | 0 | 0 | 0 |
| +0x0f0 | Gradient2_Index2 | i32 | 0 | 0 | 0 |
| +0x0f4 | Gradient2_Color1 | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x0f8 | Gradient2_Color2 | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x0fc | Gradient3_Index1 | i32 | 0 | 0 | 0 |
| +0x100 | Gradient3_Index2 | i32 | 0 | 0 | 0 |
| +0x104 | Gradient3_Color1 | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x108 | Gradient3_Color2 | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x10c | Gradient4_Index1 | i32 | 0 | 0 | 0 |
| +0x110 | Gradient4_Index2 | i32 | 0 | 0 | 0 |
| +0x114 | Gradient4_Color1 | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x118 | Gradient4_Color2 | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x11c | BloomBlurRadius | f32 | 0.55 | 0.55 | 0.556 |
| +0x120 | BloomThreshold | f32 | 1 | 1 | 1 |
| +0x124 | BloomMultiplier | f32 | 1 | 1 | 1 |
| +0x128 | BloomAmount | f32 | 0.25 | 0.25 | 0.25 |
| +0x12c | BloomTargetLuminance | f32 | 0.35 | 0.35 | 0.4 |
| +0x130 | BloomAdaptiveLuminancePercent | f32 | 0.98 | 0.98 | 0.98 |
| +0x134 | BloomAdaptiveLuminanceScale | f32 | 30 | 30.3704 | 30.3704 |
| +0x138 | BloomAdaptiveLuminanceMin | f32 | 0.01 | 0.01 | 0.01 |
| +0x13c | BloomAdaptiveLuminanceMax | f32 | 0.8 | 0.6 | 0.8 |
| +0x140 | BloomAdaptiveLuminanceMinKeyScale | f32 | 2.5 | 2.5 | 2.5 |
| +0x144 | BloomAdaptiveLuminanceMaxKeyScale | f32 | 0.45 | 0.45 | 0.85 |
| +0x148 | BloomContastLimit | f32 | 0.15 | 0.14 | 0.145 |
| +0x14c | BloomContastMultiplier | f32 | 2 | 1.9 | 1.95 |
| +0x150 | BloomGrainyOpacity | f32 | 0.5 | 0.5 | 0.5 |
| +0x154 | AshParticlesPerSecond | f32 | 0 | 0 | 0 |
| +0x158 | AmbientSound | u32 | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) |
| +0x15c | WindDirection_X | f32 | 1 | 1 | 1 |
| +0x160 | WindDirection_Y | f32 | 0.3 | 0.3 | 0.3 |
| +0x164 | WindForce | f32 | 0.006 | 0.001 | 0.003 |
| +0x168 | ScreenEffect0Speed | f32 | 0.15 | 0.075 | 0.075 |
| +0x16c | ScreenEffect0Density | f32 | 0.9 | 0.9 | 0.9 |
| +0x170 | ScreenEffect0DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x174 | ScreenEffect0DirY | f32 | 0 | 0 | 0 |
| +0x178 | ScreenEffect0Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x17c | ScreenEffect0Color | u32 | 0x8091826F rgba(111,130,145,128) | 0x5C727A8D rgba(141,122,114,92) | 0x80808080 rgba(128,128,128,128) |
| +0x180 | ScreenEffect0Type | enum | 0 | 0 | 0 |
| +0x184 | ScreenEffect1Speed | f32 | 2 | 2 | 2 |
| +0x188 | ScreenEffect1Density | f32 | 0 | 0 | 0 |
| +0x18c | ScreenEffect1DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x190 | ScreenEffect1DirY | f32 | -1 | -1 | -1 |
| +0x194 | ScreenEffect1Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x198 | ScreenEffect1Color | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x19c | ScreenEffect1Type | enum | 0 | 0 | 0 |
| +0x1a0 | ScreenEffect2Speed | f32 | 2 | 2 | 2 |
| +0x1a4 | ScreenEffect2Density | f32 | 0 | 0 | 0 |
| +0x1a8 | ScreenEffect2DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x1ac | ScreenEffect2DirY | f32 | -1 | -1 | -1 |
| +0x1b0 | ScreenEffect2Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x1b4 | ScreenEffect2Color | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x1b8 | ScreenEffect2Type | enum | 0 | 0 | 0 |
| +0x1bc | ScreenEffect3Speed | f32 | 2 | 2 | 2 |
| +0x1c0 | ScreenEffect3Density | f32 | 0 | 0 | 0 |
| +0x1c4 | ScreenEffect3DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x1c8 | ScreenEffect3DirY | f32 | -1 | -1 | -1 |
| +0x1cc | ScreenEffect3Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x1d0 | ScreenEffect3Color | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x1d4 | ScreenEffect3Type | enum | 0 | 0 | 0 |
| +0x1d8 | ScreenEffect4Speed | f32 | 2 | 2 | 2 |
| +0x1dc | ScreenEffect4Density | f32 | 0 | 0 | 0 |
| +0x1e0 | ScreenEffect4DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x1e4 | ScreenEffect4DirY | f32 | -1 | -1 | -1 |
| +0x1e8 | ScreenEffect4Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x1ec | ScreenEffect4Color | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x1f0 | ScreenEffect4Type | enum | 0 | 0 | 0 |
| +0x1f4 | ScreenEffect5Speed | f32 | 2 | 2 | 2 |
| +0x1f8 | ScreenEffect5Density | f32 | 0 | 0 | 0 |
| +0x1fc | ScreenEffect5DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x200 | ScreenEffect5DirY | f32 | -1 | -1 | -1 |
| +0x204 | ScreenEffect5Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x208 | ScreenEffect5Color | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x20c | ScreenEffect5Type | enum | 0 | 0 | 0 |
| +0x210 | ScreenEffect6Speed | f32 | 2 | 2 | 2 |
| +0x214 | ScreenEffect6Density | f32 | 0 | 0 | 0 |
| +0x218 | ScreenEffect6DirX | f32 | 0.1 | 0.1 | 0.1 |
| +0x21c | ScreenEffect6DirY | f32 | -1 | -1 | -1 |
| +0x220 | ScreenEffect6Texture | u32 | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) ['global_rain'] | 0x27AE0359 rgba(89,3,174,39) |
| +0x224 | ScreenEffect6Color | u32 | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) | 0x80808080 rgba(128,128,128,128) |
| +0x228 | ScreenEffect6Type | enum | 0 | 0 | 0 |
| +0x22c | Coverage | f32 | 1 | 0.64744 | 0.46622 |
| +0x230 | Thickness | f32 | 125 | 75 | 50 |
| +0x234 | Shape | f32 | 0.63043 | 1 | 1 |
| +0x238 | PhaseK | f32 | 0.64234 | 0.80128 | 0.40541 |
| +0x23c | PhaseScale | f32 | 0.43796 | 0.35897 | 0.17568 |
| +0x240 | DarknessK | f32 | 30 | 300 | 10 |
| +0x244 | ShadowK | f32 | 0 | 0.67391 | 0.2037 |
| +0x248 | Tone_R | f32 | 0.75 | 1.15 | 1 |
| +0x24c | Tone_G | f32 | 0.75 | 1 | 1 |
| +0x250 | Tone_B | f32 | 1 | 0.85 | 1 |
| +0x254 | LightBlend | f32 | 0.68116 | 0 | 0 |
| +0x258 | OpacitySrcMin | f32 | 0 | 0 | 0 |
| +0x25c | OpacitySrcMax | f32 | 0.25281 | 0.1859 | 1 |
| +0x260 | OpacityDstMin | f32 | 0 | 0 | 0 |
| +0x264 | OpacityDstMax | f32 | 1 | 0.64744 | 1 |
| +0x268 | Scroll_U | f32 | 0.025 | 0.008 | 0.00491 |
| +0x26c | Scroll_V | f32 | 0.025 | 0.008 | 0.00491 |
| +0x270 | Layer1_Scale | f32 | 10 | 10 | 8 |
| +0x274 | Layer2_Scale | f32 | 1 | 1 | 1 |
| +0x278 | Layer3_Scale | f32 | 4 | 4 | 2 |
| +0x27c | Layer4_Scale | f32 | 2 | 2 | 1 |
| +0x280 | AmbientEffect0Type | enum | 1 | 1 | 1 |
| +0x284 | AmbientEffect0Name | u32 | 0x00000000 rgba(0,0,0,0) | 0x00A97CEF rgba(239,124,169,0) | 0x647189BE rgba(190,137,113,100) |
| +0x288 | AmbientEffect0Radius | f32 | 35 | 25 | 25 |
| +0x28c | AmbientEffect0Height | f32 | -0.05 | 3 | 3 |
| +0x290 | AmbientEffect0Variance | f32 | 0 | 0 | 0 |
| +0x294 | AmbientEffect1Type | enum | 1 | 1 | 0 |
| +0x298 | AmbientEffect1Name | u32 | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) |
| +0x29c | AmbientEffect1Radius | f32 | 0 | 50.7042 | 0 |
| +0x2a0 | AmbientEffect1Height | f32 | 0 | -0.5 | 0 |
| +0x2a4 | AmbientEffect1Variance | f32 | 0 | 0 | 0 |
| +0x2a8 | AmbientEffect2Type | enum | 0 | 1 | 0 |
| +0x2ac | AmbientEffect2Name | u32 | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) |
| +0x2b0 | AmbientEffect2Radius | f32 | 0 | 25 | 0 |
| +0x2b4 | AmbientEffect2Height | f32 | 0 | 5 | 0 |
| +0x2b8 | AmbientEffect2Variance | f32 | 0 | 0 | 0 |
| +0x2bc | AmbientEffect3Type | enum | 0 | 0 | 0 |
| +0x2c0 | AmbientEffect3Name | u32 | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) |
| +0x2c4 | AmbientEffect3Radius | f32 | 0 | 0 | 0 |
| +0x2c8 | AmbientEffect3Height | f32 | 0 | 0 | 0 |
| +0x2cc | AmbientEffect3Variance | f32 | 0 | 0 | 0 |
| +0x2d0 | AmbientEffect4Type | enum | 0 | 0 | 0 |
| +0x2d4 | AmbientEffect4Name | u32 | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) | 0x00000000 rgba(0,0,0,0) |
| +0x2d8 | AmbientEffect4Radius | f32 | 0 | 0 | 0 |
| +0x2dc | AmbientEffect4Height | f32 | 0 | 0 | 0 |
| +0x2e0 | AmbientEffect4Variance | f32 | 0 | 0 | 0 |
