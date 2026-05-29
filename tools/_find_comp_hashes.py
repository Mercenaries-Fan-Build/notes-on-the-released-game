"""Find component names for unknown hashes."""
import sys
sys.path.insert(0, 'tools')
from pandemic_hash import pandemic_hash_m2

candidates = [
    'Path', 'Waypoint', 'Trigger', 'Spawner', 'Vehicle', 'Building',
    'Particle', 'Effect', 'Light', 'Sound', 'Camera', 'Collision',
    'Physics', 'Animation', 'Script', 'Region', 'Zone', 'Marker',
    'Node', 'Link', 'Group', 'Layer', 'Volume', 'Area', 'Bounds',
    'Target', 'Source', 'Object', 'Entity', 'Actor', 'Component',
    'Controller', 'Manager', 'System', 'Data', 'Info', 'Config',
    'State', 'Flag', 'Type', 'Class', 'Instance', 'Reference',
    'Key', 'Value', 'Index', 'Count', 'Size', 'Offset',
    'Material', 'Texture', 'Mesh', 'Model', 'Skeleton',
    'Color', 'Position', 'Rotation', 'Scale', 'Velocity',
    'Force', 'Damage', 'Health', 'Speed', 'Range', 'Radius',
    'Duration', 'Interval', 'Timer', 'Event', 'Action',
    'Behavior', 'AI', 'Navigation', 'Patrol', 'Guard',
    'HUDMapSettings', 'MapSettings', 'HUD', 'Map',
    'Weather', 'Sky', 'Fog', 'Wind', 'Rain', 'Cloud',
    'Water', 'Terrain', 'Foliage', 'Tree', 'Rock', 'Grass',
    'Decal', 'Overlay', 'Billboard', 'Sprite', 'Icon',
    'LOD', 'Distance', 'Visibility', 'Occlusion',
    'Shadow', 'Reflection', 'Refraction', 'Emission',
    'Ambient', 'Diffuse', 'Specular', 'Normal',
    'Atmosphere', 'Environment', 'Scene', 'World',
    'Level', 'Chapter', 'Mission', 'Objective',
    'Faction', 'Team', 'Player', 'Enemy', 'Ally',
    'Civilian', 'NPC', 'Boss', 'Minion', 'Squad',
    'NetworkObject', 'MultiplayerObject', 'NetworkSync',
    'LightColor', 'LightRadius', 'LightIntensity',
    'DamageRegion', 'SpawnPoint', 'CheckPoint',
    'ObjectRegistry', 'AssetReference', 'BlockReference',
    'TerrainPatch', 'TerrainTile', 'TerrainChunk',
    'VehicleSpawn', 'WeaponPickup', 'HealthPickup',
    'Destructible', 'Explosive', 'Flammable',
    'CoverPoint', 'PatrolRoute', 'AIWaypoint',
    'CutsceneTrigger', 'DialogueTrigger', 'MusicTrigger',
    'AmbientSound', 'SoundEmitter', 'MusicZone',
    'WeatherZone', 'AtmosphereZone', 'FogVolume',
    'WaterVolume', 'SwimZone', 'DeathZone',
    'NoGoZone', 'RestrictedZone', 'SafeZone',
    'HiddenObject', 'CollectibleObject', 'SecretObject',
    'DLCContent', 'DLCTrigger', 'DLCRegion',
    'Streamable', 'StreamingGroup', 'StreamingZone',
]

targets = {0x6C82EBE5, 0x6FA2F9D4, 0xBCFE6314}
for c in candidates:
    h = pandemic_hash_m2(c)
    if h in targets:
        print(f'MATCH: pandemic_hash_m2("{c}") = 0x{h:08X}')
print(f'Done checking {len(candidates)} candidates')
