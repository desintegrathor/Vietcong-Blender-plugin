# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
BES Import Module

Handles importing BES files into Blender.
"""

import bpy

# Expose submodules
from . import stg_importer


class IMPORT_OT_bes(bpy.types.Operator):
    """Import Vietcong BES file"""
    bl_idname = "import_scene.bes"
    bl_label = "Import BES"
    bl_description = "Import Vietcong BES model"
    bl_options = {'REGISTER', 'UNDO', 'PRESET'}

    filepath: bpy.props.StringProperty(subtype='FILE_PATH')
    filter_glob: bpy.props.StringProperty(default="*.bes;*.BES", options={'HIDDEN'})

    # Texture search options
    search_textures: bpy.props.BoolProperty(
        name="Search for Textures",
        description="Automatically search for texture files",
        default=True,
    )

    search_subfolders: bpy.props.BoolProperty(
        name="Search Subfolders",
        description="Search in subfolders of the model's directory",
        default=True,
    )

    search_game_folders: bpy.props.BoolProperty(
        name="Search Game Folders (G)",
        description="Search in G folder if model is in LEVELS or G folder structure",
        default=True,
    )

    # Import options
    import_materials: bpy.props.BoolProperty(
        name="Import Materials",
        description="Import materials and textures",
        default=True,
    )

    import_hierarchy: bpy.props.BoolProperty(
        name="Import Hierarchy",
        description="Preserve object hierarchy from BES file",
        default=True,
    )

    def draw(self, context):
        layout = self.layout

        # Texture options
        box = layout.box()
        box.label(text="Textures", icon='TEXTURE')
        box.prop(self, "search_textures")
        if self.search_textures:
            col = box.column()
            col.prop(self, "search_subfolders")
            col.prop(self, "search_game_folders")

        # Import options
        box = layout.box()
        box.label(text="Import Options", icon='IMPORT')
        box.prop(self, "import_materials")
        box.prop(self, "import_hierarchy")

    def execute(self, context):
        from .bes_importer import import_bes
        options = {
            'search_textures': self.search_textures,
            'search_subfolders': self.search_subfolders,
            'search_game_folders': self.search_game_folders,
            'import_materials': self.import_materials,
            'import_hierarchy': self.import_hierarchy,
        }
        return import_bes(context, self.filepath, **options)

    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}


class IMPORT_OT_stg(bpy.types.Operator):
    """Import Vietcong STG animation file"""
    bl_idname = "import_anim.stg"
    bl_label = "Import STG Animation"
    bl_description = "Import Vietcong STG animation to armature"
    bl_options = {'REGISTER', 'UNDO'}

    filepath: bpy.props.StringProperty(subtype='FILE_PATH')
    filter_glob: bpy.props.StringProperty(default="*.stg;*.STG", options={'HIDDEN'})

    def execute(self, context):
        from .stg_importer import import_stg
        return import_stg(context, self.filepath)

    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}


classes = [
    IMPORT_OT_bes,
    IMPORT_OT_stg,
]


def register():
    """Register importer classes."""
    for cls in classes:
        bpy.utils.register_class(cls)


def unregister():
    """Unregister importer classes."""
    for cls in reversed(classes):
        bpy.utils.unregister_class(cls)
