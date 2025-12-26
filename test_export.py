# Test script to run in Blender Python console
# Paste this into Blender's Python console or run as script

import bpy
import traceback

print("=" * 50)
print("Testing BES Export")
print("=" * 50)

# Check if addon is registered
try:
    from vietcong_bes.exporters import EXPORT_OT_bes
    print(f"Export operator class: {EXPORT_OT_bes}")
    print(f"bl_idname: {EXPORT_OT_bes.bl_idname}")
except Exception as e:
    print(f"ERROR loading export operator: {e}")
    traceback.print_exc()

# Check if operator is registered
try:
    op = getattr(bpy.ops.export_scene, 'bes', None)
    if op:
        print(f"Operator registered: bpy.ops.export_scene.bes")
    else:
        print("ERROR: Operator NOT registered!")
except Exception as e:
    print(f"ERROR checking operator: {e}")

# Try to call the exporter directly
try:
    from vietcong_bes.exporters.bes_exporter import BESExporter
    print(f"BESExporter class loaded: {BESExporter}")
except Exception as e:
    print(f"ERROR loading BESExporter: {e}")
    traceback.print_exc()

# Try to import bes_writer
try:
    from vietcong_bes.core.bes_writer import write_bes_file, BESWriter
    print(f"BESWriter loaded: {BESWriter}")
except Exception as e:
    print(f"ERROR loading BESWriter: {e}")
    traceback.print_exc()

print("=" * 50)
print("Test complete")
print("=" * 50)
