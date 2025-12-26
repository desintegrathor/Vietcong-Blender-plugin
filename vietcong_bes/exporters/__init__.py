# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
BES Export Module

Handles exporting Blender scenes to BES format.
"""

import bpy
from bpy_extras.io_utils import ExportHelper

# Expose submodules
from . import stg_exporter


class EXPORT_OT_bes(bpy.types.Operator, ExportHelper):
    """Export Vietcong BES file"""
    bl_idname = "export_scene.bes"
    bl_label = "Export BES"
    bl_options = {'REGISTER', 'PRESET'}

    filename_ext = ".bes"
    filter_glob: bpy.props.StringProperty(default="*.bes", options={'HIDDEN'})

    # Export options
    export_selected: bpy.props.BoolProperty(
        name="Selected Only",
        description="Export only selected objects",
        default=False,
    )
    generate_preview: bpy.props.BoolProperty(
        name="Generate Preview",
        description="Generate 64x64 preview image",
        default=True,
    )

    def execute(self, context):
        from .bes_exporter import export_bes
        return export_bes(
            context,
            self.filepath,
            export_selected=self.export_selected,
            generate_preview=self.generate_preview,
        )


class EXPORT_OT_stg(bpy.types.Operator, ExportHelper):
    """Export Vietcong STG animation file"""
    bl_idname = "export_anim.stg"
    bl_label = "Export STG Animation"
    bl_description = "Export animation to Vietcong STG format"
    bl_options = {'REGISTER', 'PRESET'}

    filename_ext = ".stg"
    filter_glob: bpy.props.StringProperty(default="*.stg;*.STG", options={'HIDDEN'})

    export_events: bpy.props.BoolProperty(
        name="Export Events (STO)",
        description="Export pose markers as STO animation events",
        default=True,
    )

    def execute(self, context):
        from .stg_exporter import export_stg
        return export_stg(context, self.filepath)

    @classmethod
    def poll(cls, context):
        # Only enable if there's an armature with animation
        obj = context.active_object
        if obj and obj.type == 'ARMATURE':
            return obj.animation_data is not None and obj.animation_data.action is not None
        return False


classes = [
    EXPORT_OT_bes,
    EXPORT_OT_stg,
]


def register():
    """Register exporter classes."""
    for cls in classes:
        bpy.utils.register_class(cls)


def unregister():
    """Unregister exporter classes."""
    for cls in reversed(classes):
        bpy.utils.unregister_class(cls)
