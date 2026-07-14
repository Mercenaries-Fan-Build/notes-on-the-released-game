# Naming-prediction targets â€” reason like a 2007-2008 Pandemic rigger

Each node below is an UNNAMED HIER node in a shipped Mercenaries 2 model. Its name exists only as
a 32-bit `pandemic_hash_m2` hash (tools/fnv.py m2()). Predict the EXACT authored name string. The
`nmodels` count = how many models share that exact hash: a HIGH count means a GENERIC, reused
convention name (e.g. every helicopter's rotor hub), which is the most predictable kind.

Positions are world-space (x=+left/-right per our measured law; y=up; z=+forward/-back).

### vz_veh_helicopter_mi35hind — MAIN ROTOR (hub+5 blades @y4.4) + TAIL ROTOR (z=-10)
  [ 29] 0xB366B8C7  UNNAMED                      parent=0x255EAB53                 pos=(+0.00,+4.38,-0.00) nmodels=12
  [ 30] 0xA998B636  UNNAMED                      parent=0xB366B8C7                 pos=(+0.00,+4.38,-0.00) nmodels=15
  [ 31] 0x8F96690F  UNNAMED                      parent=0xA998B636                 pos=(+0.00,+4.38,-0.00) nmodels=15
  [ 32] 0x7AE04F5B  UNNAMED                      parent=0x8F96690F                 pos=(+5.70,+4.63,+1.73) nmodels=4
  [ 33] 0x78ED1828  UNNAMED                      parent=0x8F96690F                 pos=(+0.17,+4.38,+6.47) nmodels=8
  [ 34] 0x62EF341D  UNNAMED                      parent=0x8F96690F                 pos=(-6.10,+4.38,+2.10) nmodels=11
  [ 35] 0xE0E7ABB2  NAMED:Y7EzN3L7               parent=0x8F96690F                 pos=(-3.43,+4.38,-4.63) nmodels=15
  [ 36] 0x02EA1FCF  UNNAMED                      parent=0x8F96690F                 pos=(+3.38,+4.63,-4.73) nmodels=14
  [ 37] 0xD06B9499  UNNAMED                      parent=0xA998B636                 pos=(+0.00,+4.38,-0.00) nmodels=15
  [ 38] 0x4CC628FA  UNNAMED                      parent=0xD06B9499                 pos=(+0.00,+4.38,-0.00) nmodels=18
  [ 39] 0x2C9F4CEC  UNNAMED                      parent=0xD06B9499                 pos=(+0.00,+4.38,-0.00) nmodels=17
  [ 40] 0x1D4F731C  UNNAMED                      parent=0x255EAB53                 pos=(+0.65,+4.77,-11.23) nmodels=15
  [ 41] 0x8EC23BD5  UNNAMED                      parent=0x1D4F731C                 pos=(+0.65,+4.77,-11.23) nmodels=15
  [ 42] 0xAE7F16A4  UNNAMED                      parent=0x8EC23BD5                 pos=(+0.65,+4.77,-11.23) nmodels=9
  [ 43] 0x17664A2B  UNNAMED                      parent=0x1D4F731C                 pos=(+0.65,+4.77,-11.23) nmodels=15
  [ 44] 0x59748439  UNNAMED                      parent=0x17664A2B                 pos=(+0.65,+4.77,-11.23) nmodels=12
  [ 45] 0x05F65F7E  UNNAMED                      parent=0x59748439                 pos=(+0.65,+4.77,-11.23) nmodels=16
  [ 46] 0xC0657B1C  UNNAMED                      parent=0x59748439                 pos=(+0.65,+4.77,-11.23) nmodels=16
  [176] 0x76943CCF  UNNAMED                      parent=0x8EC23BD5                 pos=(+0.11,+3.24,-9.97) nmodels=14

UNIVERSAL VEHICLE GROUP NODES (present in 149-172 vehicles; a destruction switch):
  0x765CD254  SWIT group node, parent=bone_frame  (in 172 models)
  0x255EAB53  INTACT branch (holds hp_seat/dock/hub)  (in 172 models)
  0x75F1F74D  RUIN branch  (in 172 models)

### vz_veh_truck_m35 — 


## Interpretation already established (build on it, don't redo it)
- mi35hind nodes 29-31: three stacked at (0,4.38,0) = the MAIN ROTOR mast/hub column (y=4.38 is
  rotor height). Nodes 32,33,34,35,36 radiate outward at that height = the 5 MAIN ROTOR BLADES
  (the Hind has a 5-blade rotor). Node 35 currently carries a JUNK name (Y7EzN3L7) from someone's
  failed brute force â€” it is really a blade. Nodes 37-39 = a second hub element (blur disc /
  swashplate?). Nodes 40-46 + 176 at z=-10 = the TAIL ROTOR assembly.
- We already cracked `bone_rotor_blade_0..5` on the Ka-29 (a DIFFERENT helicopter) â€” but the Hind
  blades are UNNAMED, so the Hind does NOT reuse those exact names. Either the blade naming is
  per-model, or these use a different convention. Your job: figure out which and predict it.
- The 3 universal group nodes (0x765CD254/0x255EAB53/0x75F1F74D) are a destruction SWIT present in
  172 vehicles. PROVEN: they are <STEM> / <STEM>_pristine / <STEM>_ruin sharing one stem; stem
  hash = m2(STEM) = 0x765CD254. RULED OUT: all <=8-char strings, every single game-corpus word,
  every 2-word game-vocab compound, and body_geometry/chassis_geometry (via M1). Stem is >=9 chars
  and NOT a word the shipped game spells. Mercs1 hint: it may be an `L1_*_geometry` group name.
