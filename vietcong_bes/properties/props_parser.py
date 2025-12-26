# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
BES Properties Parser

Parses and serializes User Defined Properties (INI-style key=value format)
used by the Vietcong game engine.

Properties format example:
    Wobble=10,20,30,1,2,3
    Lighting=1.5,2.0,128,128,255
    Doors=1,90,0,100,0
    Phy_colshp=2
    Lod=100
    Lod=200
    Lod=-1
"""

from typing import Dict, List, Any, Optional, Tuple
import re


# All known property keys and their parsing info
# Format: 'key': (parser_type, default_value, description)
PROPERTY_KEYS = {
    # Wobble Animation
    'Wobble': ('float_list', [0, 0, 0, 0, 0, 0], 'angle_x, angle_y, angle_z, speed_x, speed_y, speed_z'),

    # Lighting
    'Lighting': ('float_list', [0, 0, 0, 0, 0], 'ambient_mult, direct_mult, r, g, b'),

    # Doors
    'Doors': ('mixed_list', [1, 0, 0, 0, 0], 'type, angle/dist, affect_portal, friction, locked'),
    'DoorSound': ('string', '', 'door sound group id'),

    # LOD (special - can appear multiple times)
    'Lod': ('lod_list', [], 'LOD switch distances, -1 = hide last'),
    'LastLodAlpha': ('int', 0, '1 = enable alpha fade for last LOD'),
    'AlphaMult': ('float', 0.8, 'alpha multiplier for fading'),

    # Physics - Collision
    'Phy_WPObstacle': ('int', 0, '1 = waypoint obstacle'),
    'Phy_defmat': ('string', '- ', 'default collision material code'),
    'Phy_colshp': ('int', -1, 'collision shape for player/AI'),
    'Phy_misshp': ('int', -1, 'collision shape for missiles'),

    # Physics - Dynamic
    'Phy_weight': ('float', 0, 'object weight in kg'),
    'Phy_collide': ('int', 0, '1 = collide with PC/NPC'),
    'Phy_acceptforce': ('int', 0, '1 = accept force from PC/NPC'),
    'Phy_trash': ('int', 0, '1 = dont collide with other trash'),
    'Phy_synchronize': ('int', 0, '1 = sync via network'),
    'Phy_sound': ('string', '', 'physics sound id'),

    # Glass
    'glass': ('string', '', 'broken glass BES filename'),
    'glass_dummy': ('int', 0, '1 = glass dummy object'),
    'glass_dont_rotate': ('int', 0, '1 = dont rotate fragments'),
    'glass_dont_mirror': ('int', 0, '1 = dont mirror fragments'),

    # Sector / Portal / Occluder
    'Sector': ('int', 0, '1 = is sector'),
    'Ocluder': ('int', 0, '1 = is occluder'),
    'Portal': ('float_list', [0, 0, 0, 0, 0, 0, 0], 'max_dist, half_dist, fade_dist, r, g, b, angle'),

    # Ladder
    'Ladder': ('int', 0, '1 = upper exit forward, 2 = upper exit backward'),

    # Smooth Groups
    'Smooth': ('smooth', [0], 'angle, group1, group2, ...'),
}


def parse_user_properties(raw_text: str) -> Dict[str, Any]:
    """
    Parse raw INI-style properties text into a dictionary.

    Args:
        raw_text: Raw properties text (key=value format, one per line)

    Returns:
        Dictionary with parsed property values
    """
    if not raw_text:
        return {}

    result = {}
    lod_values = []  # Special handling for multiple Lod entries

    for line in raw_text.split('\n'):
        line = line.strip()
        if not line or '=' not in line:
            continue

        # Split only on first '=' in case value contains '='
        key, value = line.split('=', 1)
        key = key.strip()
        value = value.strip()

        # Special handling for Lod (can appear multiple times)
        if key == 'Lod':
            try:
                lod_values.append(float(value))
            except ValueError:
                pass
            continue

        # Parse based on property type
        if key in PROPERTY_KEYS:
            parser_type = PROPERTY_KEYS[key][0]
            parsed_value = _parse_value(value, parser_type)
            if parsed_value is not None:
                result[key] = parsed_value
        else:
            # Unknown property - store as string
            result[key] = value

    # Add collected LOD values
    if lod_values:
        result['Lod'] = lod_values

    return result


def _parse_value(value: str, parser_type: str) -> Any:
    """Parse a value string based on its type."""
    try:
        if parser_type == 'int':
            return int(float(value))  # Allow "1.0" to be parsed as 1
        elif parser_type == 'float':
            return float(value)
        elif parser_type == 'string':
            return value
        elif parser_type == 'float_list':
            return [float(v.strip()) for v in value.split(',')]
        elif parser_type == 'mixed_list':
            # Parse as floats but preserve int-like values
            parts = value.split(',')
            result = []
            for v in parts:
                v = v.strip()
                f = float(v)
                result.append(int(f) if f == int(f) else f)
            return result
        elif parser_type == 'smooth':
            # First value is angle, rest are group numbers
            parts = [float(v.strip()) for v in value.split(',')]
            return parts
        else:
            return value
    except (ValueError, AttributeError):
        return None


def serialize_user_properties(props: Dict[str, Any]) -> str:
    """
    Serialize a properties dictionary to INI-style text.

    Args:
        props: Dictionary of property key-value pairs

    Returns:
        INI-style text with one key=value per line
    """
    lines = []

    for key, value in props.items():
        # Special handling for Lod (multiple entries)
        if key == 'Lod' and isinstance(value, list):
            for lod_val in value:
                if lod_val == -1:
                    lines.append(f'Lod=-1')
                else:
                    lines.append(f'Lod={int(lod_val) if lod_val == int(lod_val) else lod_val}')
            continue

        # Skip empty/default values
        if value is None:
            continue
        if isinstance(value, (list, tuple)) and not value:
            continue
        if isinstance(value, str) and not value:
            continue
        if value == 0 and key in ['Phy_WPObstacle', 'Phy_collide', 'Phy_acceptforce',
                                   'Phy_trash', 'Phy_synchronize', 'glass_dummy',
                                   'glass_dont_rotate', 'glass_dont_mirror',
                                   'Sector', 'Ocluder', 'Ladder', 'LastLodAlpha']:
            continue

        # Format value
        if isinstance(value, list):
            # Check if all values are default (0)
            if all(v == 0 for v in value):
                continue
            value_str = ','.join(str(int(v) if isinstance(v, float) and v == int(v) else v) for v in value)
        elif isinstance(value, float):
            value_str = str(int(value) if value == int(value) else value)
        else:
            value_str = str(value)

        lines.append(f'{key}={value_str}')

    return '\r\n'.join(lines)


def apply_properties_to_object(obj, props: Dict[str, Any]) -> None:
    """
    Apply parsed properties to a Blender object's BES PropertyGroup.

    Args:
        obj: Blender object with 'bes' PropertyGroup
        props: Dictionary of parsed properties
    """
    if not hasattr(obj, 'bes'):
        return

    bes = obj.bes

    # Wobble
    if 'Wobble' in props:
        vals = props['Wobble']
        if len(vals) >= 6:
            bes.has_wobble = True
            bes.wobble_angle = (vals[0], vals[1], vals[2])
            bes.wobble_speed = (vals[3], vals[4], vals[5])

    # Lighting
    if 'Lighting' in props:
        vals = props['Lighting']
        if len(vals) >= 5:
            bes.has_lighting = True
            bes.light_ambient_mult = vals[0]
            bes.light_direct_mult = vals[1]
            # Colors are 0-254 in props, 0-1 in Blender
            bes.light_color = (vals[2] / 254.0, vals[3] / 254.0, vals[4] / 254.0)

    # Doors
    if 'Doors' in props:
        vals = props['Doors']
        if len(vals) >= 5:
            bes.has_door = True
            bes.door_type = str(int(vals[0]) - 1)  # 1/2 -> 0/1
            bes.door_angle = vals[1]
            bes.door_affect_portal = bool(vals[2])
            bes.door_friction = vals[3]
            bes.door_locked = bool(vals[4])

    if 'DoorSound' in props:
        # Map sound group ID to enum index
        sound_id = props['DoorSound']
        # TODO: Proper sound group mapping
        bes.door_sound = '0'

    # LOD
    if 'Lod' in props:
        bes.is_lod = True
        lod_vals = props['Lod']
        if lod_vals:
            # Check for -1 (hide last LOD)
            if -1 in lod_vals:
                # Last LOD hides
                pass
            # Store first distance as lod_distance
            positive_vals = [v for v in lod_vals if v > 0]
            if positive_vals:
                bes.lod_distance = positive_vals[0]

    if 'LastLodAlpha' in props:
        bes.last_lod_alpha = bool(props['LastLodAlpha'])

    if 'AlphaMult' in props:
        bes.alpha_mult = props['AlphaMult']

    # Physics - Collision
    if 'Phy_WPObstacle' in props:
        bes.phy_wp_obstacle = bool(props['Phy_WPObstacle'])

    if 'Phy_defmat' in props:
        bes.phy_default_mat = props['Phy_defmat']

    if 'Phy_colshp' in props:
        val = props['Phy_colshp']
        if val >= -1:
            bes.phy_col_shape = str(val + 2)  # -1,0,1,2... -> 1,2,3,4...

    if 'Phy_misshp' in props:
        val = props['Phy_misshp']
        if val >= -1:
            bes.phy_mis_shape = str(val + 2)

    # Physics - Dynamic
    if 'Phy_weight' in props:
        bes.phy_weight = props['Phy_weight']

    if 'Phy_collide' in props:
        bes.phy_collide = bool(props['Phy_collide'])

    if 'Phy_acceptforce' in props:
        bes.phy_acceptforce = bool(props['Phy_acceptforce'])

    if 'Phy_trash' in props:
        bes.phy_trash = bool(props['Phy_trash'])

    if 'Phy_synchronize' in props:
        bes.phy_synchronize = bool(props['Phy_synchronize'])

    if 'Phy_sound' in props:
        # TODO: Proper sound mapping
        bes.phy_sound = '0'

    # Glass
    if 'glass' in props:
        bes.glass_type = '1'  # Glass
    elif 'glass_dummy' in props and props['glass_dummy']:
        bes.glass_type = '2'  # Glass Dummy

    if 'glass_dont_rotate' in props:
        bes.glass_dont_rotate = bool(props['glass_dont_rotate'])

    if 'glass_dont_mirror' in props:
        bes.glass_dont_mirror = bool(props['glass_dont_mirror'])

    # Sector / Portal / Occluder
    if 'Sector' in props and props['Sector']:
        bes.sector_type = '1'
    elif 'Ocluder' in props and props['Ocluder']:
        bes.sector_type = '2'
    elif 'Portal' in props:
        vals = props['Portal']
        if len(vals) >= 7:
            bes.sector_type = '3'
            bes.portal_max_dist = vals[0]
            bes.portal_half_dist = vals[1]
            bes.portal_fade_dist = vals[2]
            bes.portal_color = (vals[3] / 254.0, vals[4] / 254.0, vals[5] / 254.0)
            bes.portal_angle = vals[6]

    # Ladder
    if 'Ladder' in props:
        val = props['Ladder']
        if val in [1, 2]:
            bes.ladder_type = str(val)


def read_properties_from_object(obj) -> Dict[str, Any]:
    """
    Read BES PropertyGroup values from a Blender object and return as dict.

    Args:
        obj: Blender object with 'bes' PropertyGroup

    Returns:
        Dictionary of property values
    """
    if not hasattr(obj, 'bes'):
        return {}

    bes = obj.bes
    props = {}

    # Wobble
    if bes.has_wobble:
        angle = bes.wobble_angle
        speed = bes.wobble_speed
        if any(v != 0 for v in angle) or any(v != 1 for v in speed):
            props['Wobble'] = [angle[0], angle[1], angle[2], speed[0], speed[1], speed[2]]

    # Lighting
    if bes.has_lighting:
        color = bes.light_color
        if bes.light_ambient_mult > 0 or bes.light_direct_mult > 0:
            props['Lighting'] = [
                bes.light_ambient_mult,
                bes.light_direct_mult,
                int(color[0] * 254),
                int(color[1] * 254),
                int(color[2] * 254)
            ]

    # Doors
    if bes.has_door:
        props['Doors'] = [
            int(bes.door_type) + 1,  # 0/1 -> 1/2
            bes.door_angle,
            1 if bes.door_affect_portal else 0,
            bes.door_friction,
            1 if bes.door_locked else 0
        ]
        # DoorSound would need proper mapping

    # LOD
    if bes.is_lod and bes.lod_distance > 0:
        lod_vals = [bes.lod_distance]
        # TODO: Support multiple LOD distances
        props['Lod'] = lod_vals

        if bes.last_lod_alpha:
            props['LastLodAlpha'] = 1

        if bes.alpha_mult != 0.8:
            props['AlphaMult'] = bes.alpha_mult

    # Physics - Collision
    if bes.phy_wp_obstacle:
        props['Phy_WPObstacle'] = 1

    if bes.phy_default_mat and bes.phy_default_mat != '- ':
        props['Phy_defmat'] = bes.phy_default_mat

    col_shape = int(bes.phy_col_shape)
    if col_shape > 1:  # 1 = None
        props['Phy_colshp'] = col_shape - 2  # 2,3,4... -> 0,1,2...

    mis_shape = int(bes.phy_mis_shape)
    if mis_shape > 1:
        props['Phy_misshp'] = mis_shape - 2

    # Physics - Dynamic
    if bes.phy_weight > 0:
        props['Phy_weight'] = bes.phy_weight

    if bes.phy_collide:
        props['Phy_collide'] = 1

    if bes.phy_acceptforce:
        props['Phy_acceptforce'] = 1

    if bes.phy_trash:
        props['Phy_trash'] = 1

    if bes.phy_synchronize:
        props['Phy_synchronize'] = 1

    # Glass
    if bes.glass_type == '1':
        props['glass'] = 'glass_rectangle.bes'  # Default
    elif bes.glass_type == '2':
        props['glass_dummy'] = 1

    if bes.glass_dont_rotate:
        props['glass_dont_rotate'] = 1

    if bes.glass_dont_mirror:
        props['glass_dont_mirror'] = 1

    # Sector / Portal / Occluder
    if bes.sector_type == '1':
        props['Sector'] = 1
    elif bes.sector_type == '2':
        props['Ocluder'] = 1
    elif bes.sector_type == '3':
        color = bes.portal_color
        props['Portal'] = [
            bes.portal_max_dist,
            bes.portal_half_dist,
            bes.portal_fade_dist,
            int(color[0] * 254),
            int(color[1] * 254),
            int(color[2] * 254),
            bes.portal_angle
        ]

    # Ladder
    if hasattr(bes, 'ladder_type') and bes.ladder_type != '0':
        props['Ladder'] = int(bes.ladder_type)

    return props
