# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
Collision Materials

Complete list of collision material codes used by Ptero-Engine-II
for physics simulation.

Source: old_3DSMax_plugin/3ds Max 7/PlugCfg/pteroColMat.en.ini
"""

from typing import List, Tuple

# Surface type flags
SURFACE_GROUND = 'ground'
SURFACE_VERTICAL = 'vertical'
SURFACE_CEILING = 'ceiling'
SURFACE_SLIPPERY = 'slippery'
SURFACE_LETHAL = 'lethal'
SURFACE_SLOW_DEATH = 'slow_death'
SURFACE_ANIMATED = 'animated'

# Complete collision material dictionary
# Key: 2-character code
# Value: (description, surface_type, special_flags)
COLLISION_MATERIALS = {
    # ═══════════════════════════════════════════════════════════════════
    # B - Swamp / Mud
    # ═══════════════════════════════════════════════════════════════════
    'B-': ('Deep swamp bottom', SURFACE_GROUND, []),
    'BB': ('Mud without water', SURFACE_GROUND, []),
    'BM': ('Shallow swamp bottom', SURFACE_GROUND, []),
    'BO': ('Puddle / edge of water', SURFACE_GROUND, []),

    # ═══════════════════════════════════════════════════════════════════
    # C - Roads
    # ═══════════════════════════════════════════════════════════════════
    'C-': ('Mud dirt road', SURFACE_GROUND, []),
    'CA': ('Asphalt road', SURFACE_GROUND, []),
    'CB': ('Concrete', SURFACE_GROUND, []),
    'CP': ('Dust dirt road', SURFACE_GROUND, []),

    # ═══════════════════════════════════════════════════════════════════
    # D - Wood
    # ═══════════════════════════════════════════════════════════════════
    'D-': ('Solid wood, thick', SURFACE_GROUND, []),
    'DC': ('Solid wood inflammable', SURFACE_GROUND, []),
    'DD': ('Solid wood penetrable', SURFACE_VERTICAL, []),
    'DK': ('Tree trunks', SURFACE_VERTICAL, []),
    'DL': ('Ashes', SURFACE_GROUND, []),
    'DN': ('Squeaking thick wood', SURFACE_GROUND, []),
    'DO': ('Burnt wood', SURFACE_GROUND, []),
    'DP': ('Perforated (fence)', SURFACE_VERTICAL, []),
    'DR': ('Wattle / baskets', SURFACE_GROUND, []),
    'DS': ('Wooden ceiling', SURFACE_CEILING, []),
    'DU': ('Narrow wood', SURFACE_GROUND, [SURFACE_ANIMATED]),
    'DV': ('Squeaking penetrable wood', SURFACE_GROUND, []),
    'DX': ('Auxiliary, transparent penetrable wood', SURFACE_GROUND, []),
    'DY': ('Slippery tree bark', SURFACE_GROUND, [SURFACE_SLIPPERY]),
    'DZ': ('Ladder', SURFACE_VERTICAL, []),

    # ═══════════════════════════════════════════════════════════════════
    # E - Pottery / Ceramics
    # ═══════════════════════════════════════════════════════════════════
    'E-': ('Pottery, vases', SURFACE_VERTICAL, []),
    'ED': ('Tiles', SURFACE_GROUND, []),
    'EZ': ('Broken pottery, splinters', SURFACE_GROUND, []),

    # ═══════════════════════════════════════════════════════════════════
    # F - Metal
    # ═══════════════════════════════════════════════════════════════════
    'F-': ('Metal in general', SURFACE_GROUND, []),
    'FG': ('Grenade', SURFACE_GROUND, []),
    'FW': ('Weapon', SURFACE_GROUND, []),
    'FS': ('Shell', SURFACE_GROUND, []),
    'FB': ('Shell', SURFACE_GROUND, []),
    'FP': ('Thin metal sheet', SURFACE_GROUND, []),
    'FD': ('Pipe', SURFACE_GROUND, []),
    'FF': ('Full barrel', SURFACE_GROUND, []),
    'FJ': ('Jeep (crashing)', SURFACE_GROUND, []),
    'FE': ('Empty barrel', SURFACE_GROUND, []),
    'FO': ('Barb wire / fence', SURFACE_VERTICAL, []),
    'FX': ('Barb wire / fence', SURFACE_GROUND, [SURFACE_SLOW_DEATH]),
    'FY': ('Slippery metal', SURFACE_GROUND, [SURFACE_SLIPPERY]),

    # ═══════════════════════════════════════════════════════════════════
    # H - Water Surface (no collisions)
    # ═══════════════════════════════════════════════════════════════════
    'H-': ('Water surface (no collisions)', SURFACE_GROUND, []),
    'HA': ('Water surface (no collisions)', SURFACE_GROUND, []),
    'HB': ('Muddy water (no collision)', SURFACE_GROUND, []),
    'HC': ('Water surface (no collisions)', SURFACE_GROUND, []),
    'HR': ('Rice fields', SURFACE_GROUND, []),

    # ═══════════════════════════════════════════════════════════════════
    # J - Jungle
    # ═══════════════════════════════════════════════════════════════════
    'J-': ('Regular jungle', SURFACE_GROUND, []),
    'JD': ('Thick jungle', SURFACE_GROUND, []),
    'JK': ('Trees, shrubs', SURFACE_VERTICAL, []),
    'JL': ('Leaves', SURFACE_GROUND, []),
    'JS': ('Treetop canopy', SURFACE_CEILING, []),
    'JX': ('Jungle', SURFACE_GROUND, [SURFACE_LETHAL]),

    # ═══════════════════════════════════════════════════════════════════
    # K - Rock
    # ═══════════════════════════════════════════════════════════════════
    'K-': ('Flat rock', SURFACE_GROUND, []),
    'KD': ('Flat rock', SURFACE_GROUND, [SURFACE_LETHAL]),
    'KK': ('Slanted rock', SURFACE_GROUND, [SURFACE_SLIPPERY]),
    'KP': ('Sand', SURFACE_GROUND, []),
    'KQ': ('Rock ceiling', SURFACE_CEILING, []),
    'KR': ('Vertical rock', SURFACE_VERTICAL, []),
    'KS': ('Gravel', SURFACE_GROUND, []),
    'KX': ('Slanted rock', SURFACE_GROUND, [SURFACE_SLOW_DEATH, SURFACE_SLIPPERY]),

    # ═══════════════════════════════════════════════════════════════════
    # P - Sandbag
    # ═══════════════════════════════════════════════════════════════════
    'PP': ('Sandbag', SURFACE_GROUND, []),

    # ═══════════════════════════════════════════════════════════════════
    # S - Glass
    # ═══════════════════════════════════════════════════════════════════
    'S-': ('Small glass', SURFACE_VERTICAL, []),
    'SO': ('Window', SURFACE_VERTICAL, []),
    'SZ': ('Broken glass', SURFACE_GROUND, []),

    # ═══════════════════════════════════════════════════════════════════
    # T - Grass / Vegetation
    # ═══════════════════════════════════════════════════════════════════
    'T-': ('Short grass', SURFACE_GROUND, []),
    'TK': ('Grass and gravel', SURFACE_GROUND, []),
    'TR': ('Rice', SURFACE_GROUND, []),
    'TS': ('Straw', SURFACE_GROUND, []),
    'TV': ('Tall grass', SURFACE_GROUND, []),
    'TX': ('Short grass', SURFACE_GROUND, [SURFACE_SLIPPERY]),
    'TZ': ('Straw from below', SURFACE_CEILING, []),

    # ═══════════════════════════════════════════════════════════════════
    # V - Water Bottom
    # ═══════════════════════════════════════════════════════════════════
    'V-': ('Deep water bottom', SURFACE_GROUND, []),
    'VM': ('Shallow water bottom', SURFACE_GROUND, []),
    'VO': ('Puddle / edge of water', SURFACE_GROUND, []),

    # ═══════════════════════════════════════════════════════════════════
    # X - Auxiliary / Nothing
    # ═══════════════════════════════════════════════════════════════════
    'X-': ('Nothing', SURFACE_GROUND, []),
    'XK': ('Auxiliary rock', SURFACE_GROUND, []),
    'XD': ('Auxiliary, transparent and penetrable wood', SURFACE_GROUND, []),
    'XB': ('Backpack, first aid, medic bag, cloth', SURFACE_GROUND, []),
    'XM': ('Flask, flashlight, knife, shovel, metal', SURFACE_GROUND, []),
    'XS': ('Case, sheath, cloth', SURFACE_GROUND, []),
    'XR': ('Radio, metal', SURFACE_GROUND, []),
    'XX': ('Phones, plastic', SURFACE_GROUND, []),
    'XY': ('Glasses, wristwatch, glass', SURFACE_GROUND, []),

    # ═══════════════════════════════════════════════════════════════════
    # Y - Soft Materials
    # ═══════════════════════════════════════════════════════════════════
    'YG': ('Rubber / tires', SURFACE_GROUND, []),
    'YI': ('Polythene', SURFACE_GROUND, []),
    'YL': ('Cloth', SURFACE_VERTICAL, []),
    'YK': ('Mad cow', SURFACE_GROUND, []),
    'YO': ('Biomass', SURFACE_GROUND, []),
    'YP': ('Paper, no stains', SURFACE_GROUND, []),
    'YQ': ('Paper impenetrable, stains', SURFACE_GROUND, []),
    'YV': ('Upholstered', SURFACE_GROUND, []),

    # ═══════════════════════════════════════════════════════════════════
    # Z - Walls / Masonry
    # ═══════════════════════════════════════════════════════════════════
    'Z-': ('Wall', SURFACE_VERTICAL, []),
    'ZB': ('Concrete', SURFACE_VERTICAL, []),
    'ZO': ('Weathered plaster', SURFACE_VERTICAL, []),
    'ZS': ('Plaster ceiling', SURFACE_CEILING, []),
    'ZH': ('Wall of clay', SURFACE_VERTICAL, []),
    'ZL': ('Wall of straw and clay', SURFACE_VERTICAL, []),
    'ZK': ('Stone wall', SURFACE_VERTICAL, []),

    # ═══════════════════════════════════════════════════════════════════
    # Special marker
    # ═══════════════════════════════════════════════════════════════════
    '**': ('Notes / comments marker', SURFACE_GROUND, []),
    '- ': ('No collision material', SURFACE_GROUND, []),
}

# Categories for UI organization
COLLISION_CATEGORIES = {
    'Swamp / Mud': ['B-', 'BB', 'BM', 'BO'],
    'Roads': ['C-', 'CA', 'CB', 'CP'],
    'Wood': ['D-', 'DC', 'DD', 'DK', 'DL', 'DN', 'DO', 'DP', 'DR', 'DS', 'DU', 'DV', 'DX', 'DY', 'DZ'],
    'Pottery': ['E-', 'ED', 'EZ'],
    'Metal': ['F-', 'FG', 'FW', 'FS', 'FB', 'FP', 'FD', 'FF', 'FJ', 'FE', 'FO', 'FX', 'FY'],
    'Water Surface': ['H-', 'HA', 'HB', 'HC', 'HR'],
    'Jungle': ['J-', 'JD', 'JK', 'JL', 'JS', 'JX'],
    'Rock': ['K-', 'KD', 'KK', 'KP', 'KQ', 'KR', 'KS', 'KX'],
    'Glass': ['S-', 'SO', 'SZ'],
    'Grass': ['T-', 'TK', 'TR', 'TS', 'TV', 'TX', 'TZ'],
    'Water Bottom': ['V-', 'VM', 'VO'],
    'Auxiliary': ['X-', 'XK', 'XD', 'XB', 'XM', 'XS', 'XR', 'XX', 'XY'],
    'Soft Materials': ['YG', 'YI', 'YL', 'YK', 'YO', 'YP', 'YQ', 'YV'],
    'Walls': ['Z-', 'ZB', 'ZO', 'ZS', 'ZH', 'ZL', 'ZK'],
    'Special': ['PP', '- ', '**'],
}


def get_collision_material_name(code: str) -> str:
    """Get human-readable name for collision material code.

    Args:
        code: 2-character collision material code

    Returns:
        Human-readable description or 'Unknown' if not found
    """
    mat = COLLISION_MATERIALS.get(code)
    if mat:
        return mat[0]
    return f'Unknown ({code})'


def get_collision_material_surface(code: str) -> str:
    """Get surface type for collision material code.

    Args:
        code: 2-character collision material code

    Returns:
        Surface type string or 'ground' as default
    """
    mat = COLLISION_MATERIALS.get(code)
    if mat:
        return mat[1]
    return SURFACE_GROUND


def get_collision_material_flags(code: str) -> List[str]:
    """Get special flags for collision material code.

    Args:
        code: 2-character collision material code

    Returns:
        List of special flag strings
    """
    mat = COLLISION_MATERIALS.get(code)
    if mat:
        return mat[2]
    return []


def get_collision_material_items() -> List[Tuple[str, str, str]]:
    """Get collision materials as Blender enum items.

    Returns:
        List of (identifier, name, description) tuples for EnumProperty
    """
    items = [('- ', '- None -', 'No collision material')]

    for category, codes in COLLISION_CATEGORIES.items():
        # Add separator for category (using empty tuple trick won't work in Blender)
        for code in codes:
            if code in COLLISION_MATERIALS:
                mat = COLLISION_MATERIALS[code]
                name = mat[0]
                surface = mat[1]
                flags = mat[2]

                # Build description
                desc = f"{surface}"
                if flags:
                    desc += f" | {', '.join(flags)}"

                items.append((code, f'{code}: {name}', desc))

    return items


def get_collision_items_by_category() -> dict:
    """Get collision materials organized by category for sub-panels.

    Returns:
        Dictionary of category_name -> list of (code, name, description) tuples
    """
    result = {}

    for category, codes in COLLISION_CATEGORIES.items():
        items = []
        for code in codes:
            if code in COLLISION_MATERIALS:
                mat = COLLISION_MATERIALS[code]
                name = mat[0]
                surface = mat[1]
                flags = mat[2]

                # Build description
                desc = f"{surface}"
                if flags:
                    desc += f" | {', '.join(flags)}"

                items.append((code, name, desc))

        result[category] = items

    return result
