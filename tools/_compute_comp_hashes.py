"""Compute pandemic hashes for all known ECS component names."""
import sys
sys.path.insert(0, 'tools')
from pandemic_hash import pandemic_hash_m2

names = [
    'Transform', 'Name', 'ModelName', 'LightObject', 'Road',
    'RoadIntersection', 'DestructionLink', 'PhysicalLink',
    'ObjectScript', 'ModifierKey', 'ScrubObject', 'LineRegion',
    'MaterialMapping', 'LandingZone', 'Label', 'Anchor',
    'LowResTerrainObject', 'HibernationControl',
    'AtmosphereBase', 'IntersectionToIntersection',
    'SoundAmbience', 'AiBehavior',
]

for n in names:
    h = pandemic_hash_m2(n)
    print(f'    0x{h:08X}: "{n}",')
