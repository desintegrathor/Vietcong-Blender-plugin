# Vietcong BES Blender Plugin - Development Log

## Project Overview
Creating a modern Blender 4.x plugin for import/export of Vietcong BES format files with full feature parity with the original 3DS Max plugin.

---

## 2024-12-04 - UI Cleanup

### Odstranění duplicitních properties

V `vietcong_bes/ui/__init__.py` byly nalezeny duplicitní properties pro sector/occluder:

**Před:**
```python
sector_type: EnumProperty(
    items=[
        ('0', 'None', 'Not a sector object'),
        ('1', 'Sector', 'Visibility sector'),
        ('2', 'Occluder', 'Occlusion culling occluder'),
        ('3', 'Portal', 'Portal between sectors'),
    ]
)

# DUPLICITNÍ - zbytečné:
is_sector: BoolProperty(...)      # řádek 416
is_occluder: BoolProperty(...)    # řádek 422
```

**Po:**
- Odstraněny `is_sector` a `is_occluder` BoolProperty
- Ponechán pouze `sector_type` EnumProperty - pokrývá všechny případy

**Soubor upraven:**
- `vietcong_bes/ui/__init__.py` - odstraněny řádky 416-426

---

## 2024-12-04 - PteroMat Faceted Flag Fix

### IDA Analysis Deep Dive

Detailed decompilation analysis of BesExport.dle revealed a critical difference between PteroMat and PteroLayer material flags.

**DumpPteroMat (sub_8BE7BC0) - PteroMat export:**
```c
// Faceted flag uses bit 1 (0x02)
*((_DWORD *)Buf1 + 2) |= v16 != 0 ? 2 : 0;  // faceted = 0x02
```

**DumpPteroLayer (sub_8BE5200) - PteroLayer export:**
```c
// Faceted flag uses bit 2 (0x04)
*((_DWORD *)Buf1 + 2) |= v57[1167] != 0 ? 4 : 0;  // faceted = 0x04
```

### Bug Fixed

**Problem:** Both PteroMat (0x1002) and PteroLayer (0x1004) parsers/writers were using `0x04` for the faceted flag.

**Fix:**
- PteroMat: Changed from `0x04` to `0x02` (bit 1)
- PteroLayer: Remains `0x04` (bit 2) - was correct

**Files modified:**
1. `vietcong_bes/core/chunk_parser.py` (line 669)
2. `vietcong_bes/core/bes_writer.py` (line 204)

### Verification Summary

From comprehensive IDA analysis, the following are confirmed correct:
- File structure (header, preview, info, root)
- Transform chunk (100 bytes)
- Material nesting (0x1000 contains 0x1002/0x1004)
- Texture coordinate config
- Collision material
- Grow/grass types

### Additional IDA Analysis Findings

**Transform Chunk (0x35) - sub_8BD3940:**
```
Offset +0:  chunk_type = 53 (0x35)
Offset +4:  chunk_size = 108 (includes 8-byte header)
Offset +8:  translation (x, y, z) - 12 bytes
Offset +20: rotation (Euler from QuatToEuler) - 12 bytes
Offset +32: scale (x, y, z) - 12 bytes
Offset +44: 4x4 matrix - 64 bytes (4 rows × 4 floats, last column padding)
```
- Uses `decomp_affine()` to decompose matrix
- Euler angles from `QuatToEuler()`
- Status: ✅ Our implementation matches

**Standard Material (0x1001) - sub_8BE9350 (DumpStdMaterial):**
```c
// Flags at offset +8
*((_DWORD *)Buf1 + 2) |= twoSided != 0;      // bit 0 = twoSided
*((_DWORD *)Buf1 + 2) |= faceted != 0 ? 2 : 0;  // bit 1 = faceted (0x02)
```
- Standard material uses same flag layout as PteroMat
- bit 0 = twoSided, bit 1 = faceted

**Mesh Export - sub_8BD1A10 (ExportFaceList):**
- Writes chunk 0x11 (17) - vertex indices
- Writes chunk 0x12 (18) - face data with smooth groups
- Writes chunk 0x13 (19) - material ID per face
- Handles UV mapping for up to 20 texture channels

**IDA Function Reference:**
| Function | Purpose |
|----------|---------|
| sub_8BDFFE0 | DoExport - main export |
| sub_8BE4A90 | ExportMaterialList |
| sub_8BE7BC0 | DumpPteroMat (0x1002) |
| sub_8BE5200 | DumpPteroLayer (0x1004) |
| sub_8BE9350 | DumpStdMaterial (0x1001) |
| sub_8BD3940 | ExportTransform (0x35) |
| sub_8BD1A10 | ExportFaceList (mesh data) |

### Potential Issue: Standard Material (0x1001) Structure

**IDA Analysis shows this structure:**
```
Offset +0:  chunk_type = 0x1001
Offset +4:  chunk_size
Offset +8:  flags (uint32) - bit 0 = twoSided, bit 1 = faceted
Offset +12: material name (4 chars)
Offset +16: texture_flags (uint32)
```

**Our current implementation reads:**
```python
material_id = read_float()    # Offset +8
unknown = read_float()         # Offset +12
map_flags = read_uint32()      # Offset +16
```

**TODO:** Verify with original BES files if this is causing issues. The current implementation might have been based on different analysis. Need roundtrip test to confirm.

---

## 2024-12-02 - Project Initialization

### Research Phase
- Analyzed existing project structure
- Reviewed old Blender plugin (import_bes.py, material_bes.py, pterocolmat.py)
- Examined 3DS Max plugin MaxScript files (pteroMat.ms, pteroLib.ms, PteroTools.ms)
- Read complete BES format specification (docs/old_documentation.md)
- Analyzed BesExport.dle in IDA Pro for export logic

### Key Findings from IDA Analysis (BesExport.dle)

**DoExport function (sub_8BDFFE0):**
- Writes BES header: magic "BES\0", version "0008", MaxSDK version
- Preview image offset: 12304 bytes from start
- Writes chunk 0x70 (Info) first after preview
- Writes chunk 0x01 (Root node) containing scene hierarchy
- Uses 0x2000000 byte buffer for export data

**ExportMaterialList function (sub_8BE4A90):**
- Writes chunk 0x1000 (Material List header)
- Iterates materials and sub-materials
- Handles both Standard and PteroMat materials

**Important strings found:**
- Material types: 'Standard', 'PteroMat', 'PteroLayer'
- Properties: transparency, surface, grassType, growType, shaderType
- Water properties: waterEnvBlend, waterAlphaAngle, waterSharpness, waterShiftingXY/UV
- Layer properties: layerFilename, layerMipmap, layerTileU/V, layerMove, etc.

### Project Structure Created

```
vietcong_bes/
├── __init__.py           # Main plugin entry, bl_info
├── core/
│   ├── __init__.py
│   ├── constants.py      # All BES format constants
│   └── bes_types.py      # Data classes
├── importers/
│   └── __init__.py       # Import operator stub
├── exporters/
│   └── __init__.py       # Export operator stub
├── ui/
│   └── __init__.py       # UI panels
├── materials/
│   ├── __init__.py
│   └── collision_materials.py
└── utils/
    ├── __init__.py
    ├── binary_utils.py   # BinaryReader/Writer classes
    └── math_utils.py     # Coordinate conversion
```

### Files Implemented

1. **core/constants.py** - Complete BES format constants:
   - Chunk type IDs (0x01, 0x30-0x36, 0x50-0x54, 0x70, 0x1000-0x1002)
   - D3DFVF flags for vertex format
   - Standard material texture flags and UV ordering
   - PteroMat texture flags and UV ordering
   - Transparency types (0x202D, 0x3023-0x3423)
   - Shader types (#0-#4 prefixes)
   - Collision material codes

2. **core/bes_types.py** - Data classes:
   - BESHeader, BESPreview, BESChunk
   - BESVertex, BESFace, BESMesh
   - BESTransform, BESWobble
   - BESTexture, BESMaterial, BESStandardMaterial, BESPteroMat
   - BESNode, BESProperties, BESInfo, BESFile
   - calculate_name_hash() function

3. **utils/binary_utils.py** - Binary I/O:
   - BinaryReader class with all read methods
   - BinaryWriter class with all write methods
   - ChunkBuilder helper class

4. **utils/math_utils.py** - Coordinate conversion:
   - bes_to_blender_coords() / blender_to_bes_coords()
   - bes_to_blender_uv() / blender_to_bes_uv()
   - bes_to_blender_rotation() / blender_to_bes_rotation()
   - Matrix conversion functions
   - Bounding sphere calculation

5. **materials/collision_materials.py** - Complete collision material list

### Technical Notes

**UV Coordinate Ordering (Critical!):**
- Standard materials: UV order in vertices differs from flag bit order
- PteroMat: Has its own UV ordering scheme
- Must use lookup tables for correct mapping

**Coordinate System:**
- BES (DirectX): X-right, Y-up, Z-forward (left-handed)
- Blender: X-right, Y-forward, Z-up (right-handed)
- Conversion: swap Y and Z, flip V coordinate for UVs

**Transform Data:**
- BES stores translation, rotation (radians!), scale separately
- 4x4 matrix also stored but may contain errors
- Always prefer decomposed values

### Implementation Progress - Phase 1 Complete

**Additional files implemented:**

6. **core/bes_reader.py** - High-level file reader:
   - BESReader class for complete file reading
   - Header validation and parsing
   - Preview image reading
   - Integration with ChunkParser

7. **core/bes_writer.py** - High-level file writer:
   - BESWriter class for complete file writing
   - ChunkBuilder integration
   - Proper chunk nesting and size calculation
   - Support for all chunk types

8. **core/chunk_parser.py** - Recursive chunk parsing:
   - Complete implementation of all chunk types
   - Object hierarchy parsing (0x01)
   - Model/Mesh/Vertices/Faces parsing (0x30-0x33)
   - Properties and Transform parsing (0x34-0x36)
   - Material parsing (0x1000-0x1002)
   - UV coordinate handling with proper ordering

9. **importers/bes_importer.py** - Blender import:
   - BESImporter class
   - Material creation with shader nodes
   - Mesh creation from BES data
   - Hierarchy preservation
   - Transform application
   - Texture loading with fallback extensions

10. **exporters/bes_exporter.py** - Blender export:
    - BESExporter class
    - Scene traversal
    - Mesh triangulation and conversion
    - Material extraction from shader nodes
    - Property conversion
    - Preview generation (placeholder)

11. **ui/__init__.py** - UI panels:
    - BES_PT_material_panel - Material properties
    - BES_PT_object_panel - Object properties (LOD, Wobble)

**Plugin Status:**
- Core import/export functionality implemented
- Ready for initial testing with real BES files
- Need test files to verify functionality

### Next Steps
1. Test with real BES files (waiting for user to provide)
2. Fix any issues found during testing
3. Implement preview generation
4. Add more UI options
5. Implement ISKE skeletal support
6. Add batch operations

---

## 2024-12-02 - Implementation Complete

### Status: Ready for Testing

All core modules have been implemented and are ready for testing:

**Implemented Files:**
- `vietcong_bes/__init__.py` - Main plugin entry point
- `vietcong_bes/core/__init__.py` - Core module exports
- `vietcong_bes/core/constants.py` - All BES format constants
- `vietcong_bes/core/bes_types.py` - Data classes for BES structures
- `vietcong_bes/core/bes_reader.py` - High-level file reader
- `vietcong_bes/core/bes_writer.py` - High-level file writer
- `vietcong_bes/core/chunk_parser.py` - Chunk parsing logic
- `vietcong_bes/utils/__init__.py` - Utility exports
- `vietcong_bes/utils/binary_utils.py` - Binary I/O classes
- `vietcong_bes/utils/math_utils.py` - Coordinate conversion
- `vietcong_bes/importers/__init__.py` - Import operator
- `vietcong_bes/importers/bes_importer.py` - Import logic
- `vietcong_bes/exporters/__init__.py` - Export operator
- `vietcong_bes/exporters/bes_exporter.py` - Export logic
- `vietcong_bes/ui/__init__.py` - UI panels
- `vietcong_bes/materials/__init__.py` - Materials module
- `vietcong_bes/materials/collision_materials.py` - Collision material list
- `tests/README.md` - Test file instructions

**Features Implemented:**
- Import: Geometry, materials (Standard + PteroMat), textures, hierarchy, transforms
- Export: Full scene export with materials, chunks, properties
- Materials: Two-sided, transparency, collision materials
- Properties: LOD, Wobble, custom properties from INI format
- Coordinate conversion: BES (DirectX) <-> Blender

**Awaiting Test Files:**
The plugin is ready for testing but requires BES files from the user.
Place test files in the `tests/` folder.

---

## Notes for Future Development

### Resources Available
- IDA Pro with game.dll (Vietcong 1.60) loaded
- IDA Pro with BesExport.dle loaded for export analysis
- Complete BES format specification in docs/
- Old Blender plugin for import reference
- 3DS Max plugin MaxScript for feature reference

### Known Challenges
1. UV ordering is different between Standard and PteroMat materials
2. Transform matrices may have calculation errors
3. Texture paths need flexible resolution (DDS/TGA/BMP)
4. IFL animated textures need special handling
5. Skeletal (ISKE) nodes are complex and partially documented

### Testing Strategy
- Create tests/ folder for sample BES files
- Test import with various BES files from Vietcong
- Test export by re-importing exported files
- Verify materials render correctly in Blender

---

## 2024-12-02 - Parser Fixes and Testing

### Test Files Added
Copied the following test files to tests/ folder:
- `FLC_CABINET1.BES` - Standard material model (version 0008)
- `IVQ_BEDNA.bes` - Simple box model (version 0100)
- `VVH_AK47_FPV.BES` - Weapon model with multiple materials (version 0008)
- `VVH_KNIFE_FPV.bes` - Knife model with PteroMat (version 0100)

### Critical Bug Fixes

**Bug 1: Chunk Size Interpretation**
- **Problem**: BES chunk size field INCLUDES the 8-byte header, but code was treating it as excluding header
- **Symptom**: Node names were truncated ("ot" instead of "Scene Root")
- **Fix**: Modified `read_chunk_header()` to subtract 8 from size: `data_size = total_size - 8`
- **File**: `vietcong_bes/utils/binary_utils.py`

**Bug 2: Object Child Count Type**
- **Problem**: Child count was being read as float instead of uint32
- **Symptom**: Incorrect child counts, parsing errors
- **Fix**: Changed `int(self._reader.read_float())` to `self._reader.read_uint32()`
- **File**: `vietcong_bes/core/chunk_parser.py`

**Bug 3: Transform Structure**
- **Problem**: Code was reading a "wobble byte" that doesn't exist in the format
- **Symptom**: Scale values were garbage (5.8e-39 instead of 1.0)
- **Fix**: Removed wobble byte read, transform is 100 bytes: translation(12) + rotation(12) + scale(12) + matrix(64)
- **File**: `vietcong_bes/core/chunk_parser.py`

**Bug 4: Material List Structure**
- **Problem**: Material chunks (0x1001/0x1002) are INSIDE the 0x1000 block, not siblings
- **Symptom**: Materials count was always 0
- **Fix**: Modified `_parse_material_list()` to recursively parse nested material chunks
- **File**: `vietcong_bes/core/chunk_parser.py`

### Test Results After Fixes

All 4 test files now parse successfully:

```
FLC_CABINET1.BES:
  - Version: 0008
  - Materials: 2 Standard (FLC_Cabinet1.dds)
  - Nodes: Scene Root -> skrinka -> multiple LOD children
  - 556 vertices, 284 faces total

IVQ_BEDNA.bes:
  - Version: 0100
  - Materials: 2 Standard (IVQ_BEDNA.DDS)
  - Nodes: Scene Root -> bedna -> viko
  - 236 vertices, 116 faces total

VVH_AK47_FPV.BES:
  - Version: 0008
  - Materials: 4 Standard (AK47.dds, Flash_a_2.tga, Flash_rem.tga, Ak47_bajonet.dds)
  - Nodes: Multiple parts (Default, Zaver, kohoutek, Zasobnik, etc.)
  - PTC attachment points (^PTC_01, ^PTC_02)
  - 1874 vertices, 1306 faces total

VVH_KNIFE_FPV.bes:
  - Version: 0100
  - Materials: 1 PteroMat (KNIFE.dds, transparency 0x202D)
  - Nodes: Scene Root -> mykinfe
  - 451 vertices, 328 faces total
```

### BesImport.dli Analysis

Decompiled BesImport.dli to understand PteroMat structure:

**PteroMat byte offsets (from sub_8B54740):**
```
+8:   flags (bit 0=twoSided, bit 2=faceted)
+12:  numTextures
+16:  surface (collision material, 9 bytes)
+20:  transparency type
+24:  growType (1 char)
+25:  grassType (1 char)
+26:  diffuse color (3 floats, 12 bytes)
+38:  ambient color (3 floats)
+50:  specular color (3 floats)
+62:  self-illum color (3 floats)
+74:  opacity (int)
+78:  opacity falloff (float)
+82:  glossiness (int)
+86:  spec level (int)
+90:  shader type string length
+94:  shader filename length
+98:  texture data offset
+102: shader type string
```

**Water properties (from string analysis):**
- waterEnvBlend, waterAlphaAngle, waterSharpness
- waterShiftingXY, waterShiftingUV

**Layer texture properties:**
- layerOrder, layerMipmap, layerTileU, layerTileV
- layerMove, layerMoveType, layerMoveSoft, layerMoving
- layerChannel, layerFilename
- layerOverlayMultitex, layerLMApplyLight, layerEnvType

### Test Script Created

Created `tests/test_parser.py` for standalone testing without Blender:
- Uses importlib to bypass bpy import
- Tests all BES files in tests/ folder
- Prints full hierarchy with materials, vertices, faces, transforms, properties

### Next Steps
1. Test import in Blender 4.x
2. Add PteroMat color properties from BesImport.dli analysis
3. Implement export functionality testing
4. Add water material support
5. Add layer texture support

---

## 2024-12-02 - Automatic Texture Search Implementation

### Feature: Intelligent Texture Path Resolution

Implemented automatic texture searching that follows Vietcong folder structure conventions.

**File modified:** `vietcong_bes/importers/bes_importer.py`

### Search Priority (in order):

1. **Same folder** as the model (exact match with case-insensitive filename)
2. **Subfolders** of model's folder (recursive search)
3. **Game structure search**:
   - If model is in `LEVELS/` → find `G/` folder at same level
   - If model is in `G/` → use current G folder root
   - Search all of G folder **excluding** `_FOR_ALL`
   - Finally search `G/TEXTURES/_FOR_ALL` as last resort

### Methods Added:

| Method | Purpose |
|--------|---------|
| `_find_texture()` | Main texture search with 3-phase priority |
| `_search_in_directory()` | Search single directory with case-insensitive matching |
| `_search_recursive()` | Recursive search with directory exclusion support |
| `_get_g_folder_path()` | Detect game root from LEVELS or G location |

### Key Features:
- **Case-insensitive matching** - works on both Windows and Linux
- **Extension fallback** - tries DDS, TGA, BMP, PNG, JPG in order
- **Performance optimized** - uses `os.scandir()` and `os.walk()`
- **Exclusion support** - skips `_FOR_ALL` during initial G folder search
- **Proper path handling** - works with both forward and backslash separators

---

## 2024-12-02 - Bug Fixes from User Testing

### Issues Reported by User
User tested the import in Blender 4.x and reported 3 issues:
1. Model rotated 90 degrees
2. Transparency shows black instead of transparent
3. No texture search configuration in import dialog

### Fix 1: 90° Rotation Issue

**Problem:** The `bes_to_blender_rotation()` function swapped Y/Z axes but didn't account for handedness change. BES uses left-handed coordinates (DirectX), Blender uses right-handed.

**Solution:** Added negation of X rotation for handedness conversion.

**File:** `vietcong_bes/utils/math_utils.py`

```python
def bes_to_blender_rotation(rot):
    # Swap Y and Z, negate X for handedness (left-handed to right-handed)
    return (-rot[0], rot[2], rot[1])
```

### Fix 2: Transparency Shows Black

**Problems Identified:**
1. `blend_method` only set for PteroMat when `is_transparent` is True
2. Alpha only connected if `blend_method == 'BLEND'`
3. Standard materials with alpha not handled
4. Missing `shadow_method` and `show_transparent_back` settings

**Solution:** Updated `_create_material()` and `_add_texture_node()` methods.

**File:** `vietcong_bes/importers/bes_importer.py`

Changes:
- Pass `needs_alpha` flag based on material transparency type
- Add `check_alpha` parameter to detect 4-channel (RGBA) images
- Set `blend_method='BLEND'`, `shadow_method='CLIP'`, `show_transparent_back=True`
- Always connect alpha output when transparency is needed

### Fix 3: Import Dialog Options

**Problem:** Import operator had no configuration options for texture search.

**Solution:** Added comprehensive options to `IMPORT_OT_bes` operator.

**File:** `vietcong_bes/importers/__init__.py`

New options added:
| Option | Description | Default |
|--------|-------------|---------|
| `search_textures` | Enable/disable texture search | True |
| `search_subfolders` | Search in subfolders of model directory | True |
| `search_game_folders` | Search in G folder for game structure | True |
| `import_materials` | Import materials and textures | True |
| `import_hierarchy` | Preserve object hierarchy | True |

The import dialog now shows these options in two boxes:
- **Textures** box with search options
- **Import Options** box with material/hierarchy options

### Files Modified
- `vietcong_bes/utils/math_utils.py` - Rotation conversion fix
- `vietcong_bes/importers/__init__.py` - Import operator UI options
- `vietcong_bes/importers/bes_importer.py` - Transparency handling, options support

### Testing Required
User should test import again with:
1. Models that were previously rotated 90°
2. Models with transparent textures (alpha channel)
3. Verify import dialog shows texture search options

---

## 2024-12-02 - Extended PteroMat Properties from IDA Analysis

### IDA Pro Analysis of BesExport.dlu

Connected to **BesExport.dlu** (3DS Max 7 BES export plugin) via IDA Pro MCP and analyzed key export functions:

| Function | Address | Purpose |
|----------|---------|---------|
| DumpPteroMat | `0x8981040` | Export PteroMat materials (chunk 0x1002) |
| DumpStdMaterial | `0x8981D60` | Export Standard materials (chunk 0x1001) |
| DumpPteroLayer | `0x897FAF0` | Export PteroLayer materials |

### Discovered Properties

**PteroMat chunk structure (0x1002):**
```
Offset 0:  Flags (bit 0=twoSided, bit 2=faceted)
Offset 4:  Texture type bitfield
Offset 8:  Collision material (2 bytes + 2 zeros)
Offset 12: Transparency type
Offset 16: Grow type (1 byte) + Grass type (1 byte) + 2 zeros
Offset 20: Name length
Offset 24: Material name
Then:      Texture map data
```

**New properties found in IDA strings:**
- `faceted` - flat shading flag
- `growType`, `grassType` - vegetation types (separate fields)
- `matDiffuse`, `matAmbient`, `matSpecular`, `matSelfIllum` - material colors
- `matOpacity`, `matOpacityFalloff` - transparency settings
- `matGlossiness`, `matSpecLevel` - surface properties
- `shaderType`, `shaderFilename` - shader references
- `isWater`, `isGlass` - special material flags
- `waterEnvBlend`, `waterAlphaAngle`, `waterSharpness` - water properties
- `waterShiftingXY`, `waterShiftingUV` - water animation

### Files Modified

**1. `vietcong_bes/core/bes_types.py`**

Extended `BESPteroMat` class with new properties:
```python
@dataclass
class BESPteroMat(BESMaterial):
    # New flags
    faceted: bool = False
    grow_type: str = ''
    grass_type: str = ''

    # Material colors
    mat_diffuse: Tuple[float, float, float] = (0.8, 0.8, 0.8)
    mat_ambient: Tuple[float, float, float] = (0.2, 0.2, 0.2)
    mat_specular: Tuple[float, float, float] = (1.0, 1.0, 1.0)
    mat_self_illum: Tuple[float, float, float] = (0.0, 0.0, 0.0)

    # Material properties
    mat_opacity: int = 100
    mat_opacity_falloff: float = 0.0
    mat_glossiness: int = 0
    mat_spec_level: int = 0

    # Shader properties
    shader_type_name: str = ''
    shader_filename: str = ''

    # Water properties (expanded)
    water_sharpness: Tuple[float, float, float] = (0.0, 0.0, 0.0)
```

**2. `vietcong_bes/core/chunk_parser.py`**

Updated `_parse_pteromat()` to:
- Parse flags field correctly (bit 0=twoSided, bit 2=faceted)
- Parse grow_type and grass_type as separate bytes
- Added documentation with IDA structure reference

**3. `vietcong_bes/core/bes_writer.py`**

Updated `_write_pteromat_to_builder()` to:
- Write flags field with faceted bit
- Write grow_type and grass_type as separate bytes
- Added IDA structure documentation

**4. `vietcong_bes/exporters/bes_exporter.py`**

Updated `_create_bes_material()` to export:
- All new PteroMat properties from custom properties
- Material colors from Principled BSDF node
- Added `_get_principled_color()` helper method

### Custom Properties for Blender Materials

Materials can now store BES-specific properties:
- `bes_faceted` - Flat shading
- `bes_grow_type`, `bes_grass_type` - Vegetation
- `bes_mat_diffuse`, `bes_mat_ambient`, etc. - Colors
- `bes_mat_opacity`, `bes_mat_glossiness`, etc. - Properties
- `bes_shader_type_name`, `bes_shader_filename` - Shaders
- `bes_is_water`, `bes_is_glass` - Special flags
- `bes_water_*` - Water animation properties

### IDA Pro MCP Tools Used

```
mcp__ida-pro-mcp__idb_meta      - Verify connection
mcp__ida-pro-mcp__list_funcs    - List functions
mcp__ida-pro-mcp__strings       - Search strings (*Ptero*, *water*, *layer*, etc.)
mcp__ida-pro-mcp__xrefs_to      - Find function references
mcp__ida-pro-mcp__decompile     - Decompile key functions
```

---

## 2024-12-04 - IDA Pro Analysis: Collision Block (0x82)

### Deep Analysis of Collision Export Functions

Performed comprehensive IDA Pro analysis of collision-related functions in BesExport.dlu:

| Function | Address | Purpose |
|----------|---------|---------|
| ExportCollision | `0x897D2D0` | Main collision export entry point |
| sub_897CFA0 | `0x897CFA0` | Collision data preparation |
| sub_897D220 | `0x897D220` | Collision mesh processing |
| sub_89712E0 | `0x89712E0` | Triangle structure building (60 bytes each) |
| sub_8973040 | `0x8973040` | Collision file format writing |

### Collision Block Structure (0x82)

```c
struct CollisionBlock {
    u32 block_type;        // 0x82 (130)
    u32 block_size;        // = vertex_size + face_size + bone_size + 39
    u32 collision_type;    // Always 2 from analysis
    u32 vertex_data_size;  // Size of vertex data in bytes
    u32 face_data_size;    // Size of face/index data in bytes
    u32 bone_data_size;    // Size of bone data (0 if no bones)
    float center_x;        // Collision mesh center
    float center_y;
    float center_z;
    // Variable data follows:
    u8 vertex_data[vertex_data_size];
    u8 face_data[face_data_size];
    u8 bone_data[bone_data_size];
};
```

### Internal Triangle Structure (60 bytes)

From analysis of `sub_89712E0`:

```c
struct CollisionTriangle {
    u8 type;           // 0=triangle, 1=sphere/helper
    u8 padding[3];
    // For type=0 (triangle):
    float v0[3];       // Vertex 0 (12 bytes)
    float v1[3];       // Vertex 1 (12 bytes)
    float v2[3];       // Vertex 2 (12 bytes)
    float unused[4];   // 16 bytes
    u32 material_id;   // Material hash (4 bytes)
    // For type=1 (sphere):
    float unused2[9];  // 36 bytes
    float pos[3];      // Sphere position (12 bytes)
    float radius;      // Radius (4 bytes)
    u32 material_id;   // Material hash (4 bytes)
};
```

### Collision File Format (sub_8973040)

Discovered complete collision file structure with magic `0xFAAB0CEE`:

```c
struct CollisionFileFormat {
    u32 magic;           // 0xFAAB0CEE
    u32 grid_count;      // Number of grid cells
    u32 edge_count;      // Number of edges
    u32 triangle_count;  // Number of triangles
    u32 sphere_count;    // Number of spheres/helpers

    // Grid cells (32 bytes each)
    // Edges (68 bytes each)
    // Triangles (112 bytes each)
    // Spheres (24 bytes each)

    // Footer:
    float bbox_min[3];   // 12 bytes
    float bbox_max[3];   // 12 bytes
    float transform[9];  // 36 bytes (3x3 matrix)
};
```

### Implementation

**Files Modified:**

1. **`vietcong_bes/core/bes_types.py`**
   - Added `BESCollision` dataclass with fields:
     - `collision_type`, `center`, `vertices`, `faces`
     - `face_materials`, `raw_vertex_data`, `raw_face_data`, `raw_bone_data`
   - Updated `BESNode` with `collision` field and `is_collision` property
   - Updated `BESFile` with `collisions` list and `total_collisions` counter

2. **`vietcong_bes/core/chunk_parser.py`**
   - Added `BESCollision` import
   - Implemented `_parse_collision()` method (lines 973-1039)
   - Added `ChunkType.COLLISION` handling in `_parse_object()`

### BESCollision Dataclass

```python
@dataclass
class BESCollision:
    """BES collision object (chunk 0x82)."""
    name: str = ''
    collision_type: int = 2
    center: Tuple[float, float, float] = (0.0, 0.0, 0.0)
    vertices: List[Tuple[float, float, float]] = field(default_factory=list)
    faces: List[Tuple[int, int, int]] = field(default_factory=list)
    face_materials: List[int] = field(default_factory=list)
    raw_vertex_data: bytes = b''
    raw_face_data: bytes = b''
    raw_bone_data: Optional[bytes] = None

    @property
    def vertex_count(self) -> int:
        return len(self.vertices)

    @property
    def face_count(self) -> int:
        return len(self.faces)

    @property
    def has_bone_data(self) -> bool:
        return self.raw_bone_data is not None and len(self.raw_bone_data) > 0
```

### Testing

Tests performed without Blender dependency using `importlib.util`:
- ✅ BESCollision dataclass creation
- ✅ BESNode.is_collision property
- ✅ BESFile.collisions list

### Related Changes from Previous Session

Also completed in this analysis session:
- ✅ Fixed texture flag names in `constants.py` (OPACITY=0x002, DISPLACEMENT=0x200, FILTER=0x400, REFLECTION=0x800)
- ✅ Fixed `slot_names` in `chunk_parser.py` and `bes_writer.py`
- ✅ Added LIGHT (0x20), HELPER (0x40), COLLISION (0x82) to ChunkType
- ✅ Added LightType enum
- ✅ Added BESLight and BESHelper dataclasses
- ✅ Implemented `_parse_light()` and `_parse_helper()` methods

### Next Steps

- ⬜ Test collision parsing on real BES files with collision data
- ⬜ Implement collision export in `bes_writer.py`

---
