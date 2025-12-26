# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
BES UI Module

User interface panels and operators for BES plugin.
Provides comprehensive material and object property editing.
"""

import bpy
from bpy.props import (
    StringProperty, BoolProperty, IntProperty, FloatProperty,
    FloatVectorProperty, EnumProperty, PointerProperty
)

from ..materials.collision_materials import (
    COLLISION_MATERIALS, COLLISION_CATEGORIES,
    get_collision_material_name, get_collision_material_items
)


# ═══════════════════════════════════════════════════════════════════════════════
# Property Groups
# ═══════════════════════════════════════════════════════════════════════════════

# Generate collision material enum items
def _get_collision_enum_items(self, context):
    """Generate collision material enum items dynamically."""
    items = [('- ', '- None -', 'No collision material', 0)]
    idx = 1
    for category, codes in COLLISION_CATEGORIES.items():
        for code in codes:
            if code in COLLISION_MATERIALS and code != '- ':
                mat = COLLISION_MATERIALS[code]
                name = mat[0]
                surface = mat[1]
                flags = mat[2]
                desc = f"{surface}"
                if flags:
                    desc += f" | {', '.join(flags)}"
                items.append((code, f'{code}: {name}', desc, idx))
                idx += 1
    return items


# Transparency type enum
TRANSPARENCY_ITEMS = [
    ('0', '- None - (opaque)', 'Fully opaque material'),
    ('1', '#0 - transparent, zbufwrite, sort', 'Standard transparency with z-buffer write and sorting'),
    ('2', '#1 - transparent, zbufwrite, sort, 1-bit alpha', 'Binary alpha (cutout) with z-buffer'),
    ('3', '#2 - translucent, no_zbufwrite, sort', 'Translucent without z-buffer write'),
    ('4', '#3 - transparent, zbufwrite, nosort, 1-bit alpha', 'Binary alpha without sorting'),
    ('5', '#4 - translucent - add with background', 'Additive blending, no z-buffer, sorted'),
]


class BESMaterialProperties(bpy.types.PropertyGroup):
    """BES-specific material properties."""

    material_type: EnumProperty(
        name="Type",
        description="BES material type",
        items=[
            ('standard', 'Standard', 'Standard 3DS Max material'),
            ('pteromat', 'PteroMat', 'Ptero-Engine material with game-specific properties'),
        ],
        default='pteromat'
    )

    collision_material: EnumProperty(
        name="Collision Material",
        description="Surface type for physics and sound effects",
        items=_get_collision_enum_items,
    )

    transparency_type: EnumProperty(
        name="Transparency",
        description="Transparency rendering mode",
        items=TRANSPARENCY_ITEMS,
        default='0'
    )

    two_sided: BoolProperty(
        name="Two Sided",
        description="Render both sides of faces",
        default=False
    )

    faceted: BoolProperty(
        name="Faceted",
        description="Use flat shading (no smooth normals)",
        default=False
    )

    # Colors
    diffuse_color: FloatVectorProperty(
        name="Diffuse",
        description="Diffuse color",
        subtype='COLOR',
        size=3,
        min=0.0, max=1.0,
        default=(0.8, 0.8, 0.8)
    )

    ambient_color: FloatVectorProperty(
        name="Ambient",
        description="Ambient color",
        subtype='COLOR',
        size=3,
        min=0.0, max=1.0,
        default=(0.2, 0.2, 0.2)
    )

    specular_color: FloatVectorProperty(
        name="Specular",
        description="Specular highlight color",
        subtype='COLOR',
        size=3,
        min=0.0, max=1.0,
        default=(0.9, 0.9, 0.9)
    )

    opacity: IntProperty(
        name="Opacity",
        description="Material opacity (0-100)",
        min=0, max=100,
        default=100
    )

    glossiness: IntProperty(
        name="Glossiness",
        description="Specular glossiness (0-100)",
        min=0, max=100,
        default=25
    )

    # Vegetation
    grass_type: StringProperty(
        name="Grass Type",
        description="Vegetation grass type code",
        maxlen=2,
        default=""
    )

    grow_type: StringProperty(
        name="Grow Type",
        description="Vegetation grow type code",
        maxlen=2,
        default=""
    )


class BESObjectProperties(bpy.types.PropertyGroup):
    """BES-specific object properties."""

    # LOD Settings
    is_lod: BoolProperty(
        name="Is LOD Object",
        description="This object is part of LOD system",
        default=False
    )

    lod_distance: FloatProperty(
        name="LOD Distance",
        description="Distance at which this LOD level activates (-1 = hide last LOD)",
        min=-1.0,
        default=100.0,
        unit='LENGTH'
    )

    last_lod_alpha: BoolProperty(
        name="Last LOD Alpha Fade",
        description="Fade out the last LOD level with alpha",
        default=False
    )

    alpha_mult: FloatProperty(
        name="Alpha Multiplier",
        description="Alpha multiplier for LOD fading",
        min=0.0, max=1.0,
        default=0.8
    )

    # Wobble Animation
    has_wobble: BoolProperty(
        name="Has Wobble",
        description="Enable wobble animation",
        default=False
    )

    wobble_angle: FloatVectorProperty(
        name="Wobble Angle",
        description="Wobble rotation angles (X, Y, Z)",
        size=3,
        default=(0.0, 0.0, 0.0)
    )

    wobble_speed: FloatVectorProperty(
        name="Wobble Speed",
        description="Wobble animation speeds (X, Y, Z)",
        size=3,
        default=(1.0, 1.0, 1.0)
    )

    # Lighting
    has_lighting: BoolProperty(
        name="Custom Lighting",
        description="Use custom lighting settings",
        default=False
    )

    light_ambient_mult: FloatProperty(
        name="Ambient Multiplier",
        description="Ambient light multiplier",
        min=0.0, max=99.0,
        default=1.0
    )

    light_direct_mult: FloatProperty(
        name="Direct Multiplier",
        description="Direct light multiplier",
        min=0.0, max=99.0,
        default=1.0
    )

    light_color: FloatVectorProperty(
        name="Light Color",
        description="Custom light color tint",
        subtype='COLOR',
        size=3,
        min=0.0, max=1.0,
        default=(1.0, 1.0, 1.0)
    )

    # Physics / Collision
    phy_wp_obstacle: BoolProperty(
        name="Waypoint Obstacle",
        description="Object is an obstacle for AI waypoints",
        default=False
    )

    phy_default_mat: StringProperty(
        name="Default Surface",
        description="Default collision material for this object",
        maxlen=2,
        default="- "
    )

    phy_col_shape: EnumProperty(
        name="Player Collision",
        description="Collision shape for player/AI",
        items=[
            ('1', 'None', 'No collision'),
            ('2', 'Linked', 'Use linked collision mesh'),
            ('3', 'Bounding Box', 'Use bounding box'),
            ('4', 'Render Faces', 'Use render mesh faces'),
            ('5', 'Bounding Sphere', 'Use bounding sphere'),
            ('6', 'Crazy Bounding Sphere', 'Extended bounding sphere'),
            ('7', 'Point', 'Single point collision'),
            ('8', 'Crazy Point', 'Extended point collision'),
        ],
        default='4'
    )

    phy_mis_shape: EnumProperty(
        name="Missile Collision",
        description="Collision shape for projectiles",
        items=[
            ('1', 'None', 'No collision'),
            ('2', 'Linked', 'Use linked collision mesh'),
            ('3', 'Bounding Box', 'Use bounding box'),
            ('4', 'Render Faces', 'Use render mesh faces'),
            ('5', 'Bounding Sphere', 'Use bounding sphere'),
        ],
        default='4'
    )

    # Physics 2 - Dynamic objects
    phy_weight: FloatProperty(
        name="Weight",
        description="Object weight in kg",
        min=0.0, max=65535.0,
        default=0.0
    )

    phy_collide: BoolProperty(
        name="Collide with PC/NPC",
        description="Object collides with player and NPCs",
        default=False
    )

    phy_acceptforce: BoolProperty(
        name="Accept Force",
        description="Object accepts force from player and NPCs",
        default=False
    )

    phy_trash: BoolProperty(
        name="Trash",
        description="Don't collide with other trash objects",
        default=False
    )

    phy_synchronize: BoolProperty(
        name="Synchronize",
        description="Synchronize object state via network",
        default=False
    )

    phy_sound: EnumProperty(
        name="Sound",
        description="Sound group for collision",
        items=[
            ('0', 'None', 'No sound'),
            ('1', 'Wood', 'Wood impact sound'),
            ('2', 'Metal', 'Metal impact sound'),
            ('3', 'Glass', 'Glass impact sound'),
            ('4', 'Stone', 'Stone impact sound'),
        ],
        default='0'
    )

    # Doors
    has_door: BoolProperty(
        name="Is Door",
        description="Object is a door or movable physics object",
        default=False
    )

    door_type: EnumProperty(
        name="Door Type",
        description="Type of door movement",
        items=[
            ('0', 'Pivoted', 'Door rotates around pivot'),
            ('1', 'Sliding', 'Door slides linearly'),
        ],
        default='0'
    )

    door_angle: FloatProperty(
        name="Angle/Distance",
        description="Rotation angle (degrees) or slide distance",
        min=-65535.0, max=65535.0,
        default=90.0
    )

    door_friction: FloatProperty(
        name="Friction",
        description="Door friction in Newtons",
        min=0.0, max=65535.0,
        default=0.0
    )

    door_affect_portal: BoolProperty(
        name="Affect Portal",
        description="Door opening affects connected portal",
        default=False
    )

    door_locked: BoolProperty(
        name="Locked",
        description="Door is locked by default",
        default=False
    )

    door_sound: EnumProperty(
        name="Sound Group",
        description="Sound group for door",
        items=[
            ('0', 'None', 'No sound'),
            ('1', 'Wood Door', 'Wooden door sounds'),
            ('2', 'Metal Door', 'Metal door sounds'),
            ('3', 'Gate', 'Gate sounds'),
        ],
        default='0'
    )

    # Glass
    glass_type: EnumProperty(
        name="Glass Type",
        description="Glass object type",
        items=[
            ('0', 'None', 'Not a glass object'),
            ('1', 'Glass', 'Breakable glass'),
            ('2', 'Glass Dummy', 'Glass helper object'),
        ],
        default='0'
    )

    glass_dont_rotate: BoolProperty(
        name="Don't Rotate",
        description="Don't rotate glass fragments when broken",
        default=False
    )

    glass_dont_mirror: BoolProperty(
        name="Don't Mirror",
        description="Don't mirror glass fragments when broken",
        default=False
    )

    # Ladder
    ladder_type: EnumProperty(
        name="Ladder Type",
        description="Ladder upper exit direction",
        items=[
            ('0', 'None', 'Not a ladder'),
            ('1', 'Upper Exit Forward', 'Exit forward at top'),
            ('2', 'Upper Exit Backward', 'Exit backward at top'),
        ],
        default='0'
    )

    # Sector / Portal
    sector_type: EnumProperty(
        name="Sector Type",
        description="Sector/visibility type",
        items=[
            ('0', 'None', 'Not a sector object'),
            ('1', 'Sector', 'Visibility sector'),
            ('2', 'Occluder', 'Occlusion culling occluder'),
            ('3', 'Portal', 'Portal between sectors'),
        ],
        default='0'
    )

    portal_max_dist: FloatProperty(
        name="Max Active Distance",
        description="Maximum distance at which portal is active",
        min=0.0,
        default=1000.0,
        unit='LENGTH'
    )

    portal_half_dist: FloatProperty(
        name="Half Open Distance",
        description="Distance at which portal is half open",
        min=0.0,
        default=500.0,
        unit='LENGTH'
    )

    portal_fade_dist: FloatProperty(
        name="Fade Start Distance",
        description="Distance at which portal starts to fade",
        min=0.0,
        default=800.0,
        unit='LENGTH'
    )

    portal_angle: FloatProperty(
        name="Marginal Angle",
        description="Marginal angle for portal visibility",
        min=0.0, max=90.0,
        default=45.0,
        subtype='ANGLE'
    )

    portal_color: FloatVectorProperty(
        name="Portal Color",
        description="Debug color for portal visualization",
        subtype='COLOR',
        size=3,
        min=0.0, max=1.0,
        default=(0.0, 1.0, 0.0)
    )


# ═══════════════════════════════════════════════════════════════════════════════
# Material Panels
# ═══════════════════════════════════════════════════════════════════════════════

class BES_PT_material_main(bpy.types.Panel):
    """Main BES Material Panel"""
    bl_label = "BES Material"
    bl_idname = "BES_PT_material_main"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "material"

    @classmethod
    def poll(cls, context):
        return context.material is not None

    def draw(self, context):
        layout = self.layout
        mat = context.material

        # Check for BES properties
        if not hasattr(mat, 'bes'):
            layout.label(text="Enable BES properties below", icon='INFO')
            layout.operator("bes.init_material", text="Initialize BES Material", icon='ADD')
            return

        bes = mat.bes
        layout.use_property_split = True
        layout.use_property_decorate = False

        # Material Type
        layout.prop(bes, "material_type")


class BES_PT_material_surface(bpy.types.Panel):
    """BES Material Surface Properties"""
    bl_label = "Surface"
    bl_idname = "BES_PT_material_surface"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "material"
    bl_parent_id = "BES_PT_material_main"

    @classmethod
    def poll(cls, context):
        return context.material is not None and hasattr(context.material, 'bes')

    def draw(self, context):
        layout = self.layout
        bes = context.material.bes
        layout.use_property_split = True
        layout.use_property_decorate = False

        # Collision Material with category info
        col = layout.column()
        col.prop(bes, "collision_material")

        # Show surface type info
        if bes.collision_material in COLLISION_MATERIALS:
            mat_info = COLLISION_MATERIALS[bes.collision_material]
            box = layout.box()
            row = box.row()
            row.label(text=f"Surface: {mat_info[1]}", icon='PHYSICS')
            if mat_info[2]:
                row = box.row()
                row.label(text=f"Flags: {', '.join(mat_info[2])}", icon='MODIFIER')


class BES_PT_material_rendering(bpy.types.Panel):
    """BES Material Rendering Properties"""
    bl_label = "Rendering"
    bl_idname = "BES_PT_material_rendering"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "material"
    bl_parent_id = "BES_PT_material_main"

    @classmethod
    def poll(cls, context):
        return context.material is not None and hasattr(context.material, 'bes')

    def draw(self, context):
        layout = self.layout
        bes = context.material.bes
        layout.use_property_split = True
        layout.use_property_decorate = False

        layout.prop(bes, "transparency_type")

        row = layout.row(heading="Options")
        row.prop(bes, "two_sided")
        row.prop(bes, "faceted")


class BES_PT_material_colors(bpy.types.Panel):
    """BES Material Colors"""
    bl_label = "Colors"
    bl_idname = "BES_PT_material_colors"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "material"
    bl_parent_id = "BES_PT_material_main"
    bl_options = {'DEFAULT_CLOSED'}

    @classmethod
    def poll(cls, context):
        return context.material is not None and hasattr(context.material, 'bes')

    def draw(self, context):
        layout = self.layout
        bes = context.material.bes
        layout.use_property_split = True
        layout.use_property_decorate = False

        layout.prop(bes, "diffuse_color")
        layout.prop(bes, "ambient_color")
        layout.prop(bes, "specular_color")
        layout.separator()
        layout.prop(bes, "opacity")
        layout.prop(bes, "glossiness")


class BES_PT_material_vegetation(bpy.types.Panel):
    """BES Material Vegetation Properties"""
    bl_label = "Vegetation"
    bl_idname = "BES_PT_material_vegetation"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "material"
    bl_parent_id = "BES_PT_material_main"
    bl_options = {'DEFAULT_CLOSED'}

    @classmethod
    def poll(cls, context):
        return context.material is not None and hasattr(context.material, 'bes')

    def draw(self, context):
        layout = self.layout
        bes = context.material.bes
        layout.use_property_split = True
        layout.use_property_decorate = False

        layout.prop(bes, "grass_type")
        layout.prop(bes, "grow_type")


# ═══════════════════════════════════════════════════════════════════════════════
# Object Panels
# ═══════════════════════════════════════════════════════════════════════════════

class BES_PT_object_main(bpy.types.Panel):
    """Main BES Object Panel"""
    bl_label = "BES Properties"
    bl_idname = "BES_PT_object_main"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "object"

    @classmethod
    def poll(cls, context):
        return context.object is not None

    def draw(self, context):
        layout = self.layout
        obj = context.object

        if not hasattr(obj, 'bes'):
            layout.label(text="Enable BES properties below", icon='INFO')
            layout.operator("bes.init_object", text="Initialize BES Object", icon='ADD')
            return

        # Just a header, sub-panels show the actual properties
        layout.label(text="Configure BES-specific properties in the panels below", icon='PREFERENCES')


class BES_PT_user_properties(bpy.types.Panel):
    """BES User Defined Properties Panel - displays raw properties like 3ds Max"""
    bl_label = "User Defined Properties"
    bl_idname = "BES_PT_user_properties"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "object"
    bl_parent_id = "BES_PT_object_main"

    @classmethod
    def poll(cls, context):
        return context.object is not None

    def draw(self, context):
        layout = self.layout
        obj = context.object

        # Sync buttons row
        row = layout.row(align=True)
        row.operator("bes.sync_props_to_ui", text="", icon='IMPORT')
        row.operator("bes.sync_ui_to_props", text="", icon='EXPORT')
        row.operator("bes.acquire_properties", text="", icon='PASTEDOWN')
        row.operator("bes.clear_properties", text="", icon='X')

        # Get raw User Defined Properties text
        props_text = obj.get('bes_user_properties', '')

        if props_text:
            box = layout.box()
            for line in props_text.split('\n'):
                line = line.strip()
                if line:
                    # Highlight key=value format
                    if '=' in line:
                        key, val = line.split('=', 1)
                        row = box.row()
                        row.label(text=f"{key}=")
                        row.label(text=val)
                    else:
                        box.label(text=line)
        else:
            layout.label(text="(no properties)", icon='INFO')


class BES_PT_object_wobble(bpy.types.Panel):
    """BES Wobble Animation Panel"""
    bl_label = "Wobble Animation"
    bl_idname = "BES_PT_object_wobble"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "object"
    bl_parent_id = "BES_PT_object_main"
    bl_options = {'DEFAULT_CLOSED'}

    @classmethod
    def poll(cls, context):
        return context.object is not None and hasattr(context.object, 'bes')

    def draw_header(self, context):
        self.layout.prop(context.object.bes, "has_wobble", text="")

    def draw(self, context):
        layout = self.layout
        bes = context.object.bes
        layout.use_property_split = True
        layout.use_property_decorate = False
        layout.active = bes.has_wobble

        col = layout.column(align=True)
        col.prop(bes, "wobble_angle", text="Angle")

        col = layout.column(align=True)
        col.prop(bes, "wobble_speed", text="Speed")


class BES_PT_object_lighting(bpy.types.Panel):
    """BES Custom Lighting Panel"""
    bl_label = "Custom Lighting"
    bl_idname = "BES_PT_object_lighting"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "object"
    bl_parent_id = "BES_PT_object_main"
    bl_options = {'DEFAULT_CLOSED'}

    @classmethod
    def poll(cls, context):
        return context.object is not None and hasattr(context.object, 'bes')

    def draw_header(self, context):
        self.layout.prop(context.object.bes, "has_lighting", text="")

    def draw(self, context):
        layout = self.layout
        bes = context.object.bes
        layout.use_property_split = True
        layout.use_property_decorate = False
        layout.active = bes.has_lighting

        layout.prop(bes, "light_ambient_mult")
        layout.prop(bes, "light_direct_mult")
        layout.prop(bes, "light_color")


class BES_PT_object_physics(bpy.types.Panel):
    """BES Physics / Collision Panel"""
    bl_label = "Physics & Collision"
    bl_idname = "BES_PT_object_physics"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "object"
    bl_parent_id = "BES_PT_object_main"
    bl_options = {'DEFAULT_CLOSED'}

    @classmethod
    def poll(cls, context):
        return context.object is not None and hasattr(context.object, 'bes')

    def draw(self, context):
        layout = self.layout
        bes = context.object.bes
        layout.use_property_split = True
        layout.use_property_decorate = False

        # Collision shapes
        layout.label(text="Collision Shapes:", icon='MOD_PHYSICS')
        layout.prop(bes, "phy_default_mat")
        layout.prop(bes, "phy_col_shape")
        layout.prop(bes, "phy_mis_shape")
        layout.prop(bes, "phy_wp_obstacle")

        layout.separator()

        # Dynamic physics
        layout.label(text="Dynamic Physics:", icon='RIGID_BODY')
        layout.prop(bes, "phy_weight")
        layout.prop(bes, "phy_collide")
        layout.prop(bes, "phy_acceptforce")
        layout.prop(bes, "phy_trash")
        layout.prop(bes, "phy_synchronize")
        layout.prop(bes, "phy_sound")


class BES_PT_object_doors(bpy.types.Panel):
    """BES Doors Panel"""
    bl_label = "Doors"
    bl_idname = "BES_PT_object_doors"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "object"
    bl_parent_id = "BES_PT_object_main"
    bl_options = {'DEFAULT_CLOSED'}

    @classmethod
    def poll(cls, context):
        return context.object is not None and hasattr(context.object, 'bes')

    def draw_header(self, context):
        self.layout.prop(context.object.bes, "has_door", text="")

    def draw(self, context):
        layout = self.layout
        bes = context.object.bes
        layout.use_property_split = True
        layout.use_property_decorate = False
        layout.active = bes.has_door

        layout.prop(bes, "door_type")

        # Change label based on door type
        if bes.door_type == '0':  # Pivoted
            layout.prop(bes, "door_angle", text="Angle (degrees)")
        else:  # Sliding
            layout.prop(bes, "door_angle", text="Distance")

        layout.prop(bes, "door_friction")
        layout.separator()
        layout.prop(bes, "door_affect_portal")
        layout.prop(bes, "door_locked")
        layout.separator()
        layout.prop(bes, "door_sound")


class BES_PT_object_glass(bpy.types.Panel):
    """BES Glass Panel"""
    bl_label = "Glass"
    bl_idname = "BES_PT_object_glass"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "object"
    bl_parent_id = "BES_PT_object_main"
    bl_options = {'DEFAULT_CLOSED'}

    @classmethod
    def poll(cls, context):
        return context.object is not None and hasattr(context.object, 'bes')

    def draw(self, context):
        layout = self.layout
        bes = context.object.bes
        layout.use_property_split = True
        layout.use_property_decorate = False

        layout.prop(bes, "glass_type")

        # Only show options if glass is enabled
        if bes.glass_type != '0':
            layout.separator()
            layout.prop(bes, "glass_dont_rotate")
            layout.prop(bes, "glass_dont_mirror")


class BES_PT_object_sector(bpy.types.Panel):
    """BES Sector / Visibility Panel"""
    bl_label = "Sector & Visibility"
    bl_idname = "BES_PT_object_sector"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "object"
    bl_parent_id = "BES_PT_object_main"
    bl_options = {'DEFAULT_CLOSED'}

    @classmethod
    def poll(cls, context):
        return context.object is not None and hasattr(context.object, 'bes')

    def draw(self, context):
        layout = self.layout
        bes = context.object.bes
        layout.use_property_split = True
        layout.use_property_decorate = False

        layout.prop(bes, "sector_type")

        # Show portal properties when Portal type is selected
        if bes.sector_type == '3':  # Portal
            layout.separator()
            layout.label(text="Portal Properties:", icon='EMPTY_ARROWS')
            layout.prop(bes, "portal_max_dist")
            layout.prop(bes, "portal_half_dist")
            layout.prop(bes, "portal_fade_dist")
            layout.prop(bes, "portal_angle")
            layout.prop(bes, "portal_color")


class BES_PT_object_lod(bpy.types.Panel):
    """BES LOD (Level of Detail) Panel"""
    bl_label = "LOD (Level of Detail)"
    bl_idname = "BES_PT_object_lod"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "object"
    bl_parent_id = "BES_PT_object_main"
    bl_options = {'DEFAULT_CLOSED'}

    @classmethod
    def poll(cls, context):
        return context.object is not None and hasattr(context.object, 'bes')

    def draw_header(self, context):
        self.layout.prop(context.object.bes, "is_lod", text="")

    def draw(self, context):
        layout = self.layout
        bes = context.object.bes
        layout.use_property_split = True
        layout.use_property_decorate = False
        layout.active = bes.is_lod

        layout.prop(bes, "lod_distance")
        layout.separator()
        layout.prop(bes, "last_lod_alpha")

        # Show alpha mult only when last_lod_alpha is enabled
        if bes.last_lod_alpha:
            layout.prop(bes, "alpha_mult")


class BES_PT_object_ladder(bpy.types.Panel):
    """BES Ladder Panel"""
    bl_label = "Ladder"
    bl_idname = "BES_PT_object_ladder"
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = "object"
    bl_parent_id = "BES_PT_object_main"
    bl_options = {'DEFAULT_CLOSED'}

    @classmethod
    def poll(cls, context):
        return context.object is not None and hasattr(context.object, 'bes')

    def draw(self, context):
        layout = self.layout
        bes = context.object.bes
        layout.use_property_split = True
        layout.use_property_decorate = False

        layout.prop(bes, "ladder_type")

        # Show info when ladder is enabled
        if bes.ladder_type != '0':
            box = layout.box()
            if bes.ladder_type == '1':
                box.label(text="Player exits forward at top", icon='TRIA_UP')
            else:
                box.label(text="Player exits backward at top", icon='TRIA_DOWN')


# ═══════════════════════════════════════════════════════════════════════════════
# Operators
# ═══════════════════════════════════════════════════════════════════════════════

class BES_OT_init_material(bpy.types.Operator):
    """Initialize BES properties on material"""
    bl_idname = "bes.init_material"
    bl_label = "Initialize BES Material"
    bl_options = {'REGISTER', 'UNDO'}

    @classmethod
    def poll(cls, context):
        return context.material is not None

    def execute(self, context):
        # Properties are automatically initialized when accessed
        # Just trigger access to ensure they exist
        _ = context.material.bes.material_type
        self.report({'INFO'}, f"BES properties initialized for {context.material.name}")
        return {'FINISHED'}


class BES_OT_init_object(bpy.types.Operator):
    """Initialize BES properties on object"""
    bl_idname = "bes.init_object"
    bl_label = "Initialize BES Object"
    bl_options = {'REGISTER', 'UNDO'}

    @classmethod
    def poll(cls, context):
        return context.object is not None

    def execute(self, context):
        # Properties are automatically initialized when accessed
        _ = context.object.bes.is_lod
        self.report({'INFO'}, f"BES properties initialized for {context.object.name}")
        return {'FINISHED'}


class BES_OT_assign_collision_material(bpy.types.Operator):
    """Assign collision material to selected objects' materials"""
    bl_idname = "bes.assign_collision_material"
    bl_label = "Assign Collision Material"
    bl_options = {'REGISTER', 'UNDO'}

    collision_code: StringProperty(
        name="Code",
        description="2-character collision material code",
        maxlen=2,
        default="- "
    )

    @classmethod
    def poll(cls, context):
        return context.selected_objects

    def execute(self, context):
        count = 0
        for obj in context.selected_objects:
            if obj.type == 'MESH' and obj.data.materials:
                for mat in obj.data.materials:
                    if mat and hasattr(mat, 'bes'):
                        mat.bes.collision_material = self.collision_code
                        count += 1

        self.report({'INFO'}, f"Assigned {self.collision_code} to {count} materials")
        return {'FINISHED'}


class BES_OT_sync_props_to_ui(bpy.types.Operator):
    """Load properties from raw text into UI panels"""
    bl_idname = "bes.sync_props_to_ui"
    bl_label = "Sync Properties to UI"
    bl_options = {'REGISTER', 'UNDO'}

    @classmethod
    def poll(cls, context):
        return context.object is not None

    def execute(self, context):
        from ..properties import parse_user_properties, apply_properties_to_object

        obj = context.object
        raw_text = obj.get('bes_user_properties', '')

        if not raw_text:
            self.report({'INFO'}, "No properties to sync")
            return {'CANCELLED'}

        # Parse and apply
        props = parse_user_properties(raw_text)
        apply_properties_to_object(obj, props)

        self.report({'INFO'}, f"Synced {len(props)} properties to UI")
        return {'FINISHED'}


class BES_OT_sync_ui_to_props(bpy.types.Operator):
    """Write UI values to raw properties text"""
    bl_idname = "bes.sync_ui_to_props"
    bl_label = "Sync UI to Properties"
    bl_options = {'REGISTER', 'UNDO'}

    @classmethod
    def poll(cls, context):
        return context.object is not None and hasattr(context.object, 'bes')

    def execute(self, context):
        from ..properties import read_properties_from_object, serialize_user_properties

        obj = context.object

        # Read from UI and serialize
        props = read_properties_from_object(obj)
        raw_text = serialize_user_properties(props)

        # Store in custom property
        obj['bes_user_properties'] = raw_text

        self.report({'INFO'}, f"Synced UI to properties ({len(props)} keys)")
        return {'FINISHED'}


class BES_OT_acquire_properties(bpy.types.Operator):
    """Copy properties from another object"""
    bl_idname = "bes.acquire_properties"
    bl_label = "Acquire Properties"
    bl_options = {'REGISTER', 'UNDO'}

    @classmethod
    def poll(cls, context):
        return context.object is not None and len(context.selected_objects) >= 2

    def execute(self, context):
        from ..properties import parse_user_properties, apply_properties_to_object

        target = context.object
        # Find source (first selected that isn't the active)
        source = None
        for obj in context.selected_objects:
            if obj != target:
                source = obj
                break

        if not source:
            self.report({'WARNING'}, "Select a source object")
            return {'CANCELLED'}

        # Copy raw properties
        raw_text = source.get('bes_user_properties', '')
        if raw_text:
            target['bes_user_properties'] = raw_text

            # Also apply to UI
            props = parse_user_properties(raw_text)
            apply_properties_to_object(target, props)

            self.report({'INFO'}, f"Acquired properties from {source.name}")
        else:
            self.report({'INFO'}, f"No properties on {source.name}")

        return {'FINISHED'}


class BES_OT_clear_properties(bpy.types.Operator):
    """Clear all BES properties"""
    bl_idname = "bes.clear_properties"
    bl_label = "Clear Properties"
    bl_options = {'REGISTER', 'UNDO'}

    @classmethod
    def poll(cls, context):
        return context.object is not None

    def execute(self, context):
        obj = context.object

        # Clear raw text
        if 'bes_user_properties' in obj:
            del obj['bes_user_properties']

        # Reset PropertyGroup to defaults if it exists
        if hasattr(obj, 'bes'):
            bes = obj.bes
            bes.has_wobble = False
            bes.has_lighting = False
            bes.has_door = False
            bes.is_lod = False
            bes.glass_type = '0'
            bes.sector_type = '0'
            bes.ladder_type = '0'
            bes.phy_wp_obstacle = False
            bes.phy_collide = False
            bes.phy_acceptforce = False
            bes.phy_trash = False
            bes.phy_synchronize = False

        self.report({'INFO'}, "Properties cleared")
        return {'FINISHED'}


# ═══════════════════════════════════════════════════════════════════════════════
# Registration
# ═══════════════════════════════════════════════════════════════════════════════

classes = [
    # Property Groups
    BESMaterialProperties,
    BESObjectProperties,

    # Material Panels
    BES_PT_material_main,
    BES_PT_material_surface,
    BES_PT_material_rendering,
    BES_PT_material_colors,
    BES_PT_material_vegetation,

    # Object Panels
    BES_PT_object_main,
    BES_PT_user_properties,
    BES_PT_object_wobble,
    BES_PT_object_lighting,
    BES_PT_object_physics,
    BES_PT_object_doors,
    BES_PT_object_glass,
    BES_PT_object_sector,
    BES_PT_object_lod,
    BES_PT_object_ladder,

    # Operators
    BES_OT_init_material,
    BES_OT_init_object,
    BES_OT_assign_collision_material,
    BES_OT_sync_props_to_ui,
    BES_OT_sync_ui_to_props,
    BES_OT_acquire_properties,
    BES_OT_clear_properties,
]


def register():
    """Register UI classes."""
    for cls in classes:
        bpy.utils.register_class(cls)

    # Register property groups to materials and objects
    bpy.types.Material.bes = PointerProperty(type=BESMaterialProperties)
    bpy.types.Object.bes = PointerProperty(type=BESObjectProperties)


def unregister():
    """Unregister UI classes."""
    # Remove property groups
    del bpy.types.Object.bes
    del bpy.types.Material.bes

    for cls in reversed(classes):
        bpy.utils.unregister_class(cls)
