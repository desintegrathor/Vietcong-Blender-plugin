# IDA Pro Analysis of BesExport.dlu

Documentation of findings from reverse engineering BesExport.dlu (3DS Max plugin for exporting BES files).
Combined with official Pteromatic documentation (pteroengine_max.pdf).

## Implemented Features

### Surface Property (PteroLayer)
- 4-character surface code (e.g., "GRAS", "CONC", "WOOD")
- Located after flags in PteroLayer chunk (0x1004)
- Stored as `bes_surface` custom property in Blender

### Collision Objects
- Objects with `^K` prefix are collision meshes
- `ExtDummy` objects are collision helpers
- Warnings shown when collision mesh has >50 faces or >70% of render mesh
- Stored as `bes_is_collision` custom property

### Extended Object Prefixes (from PDF)
| Prefix | Type | Description |
|--------|------|-------------|
| `^K` | Collision | Player collision mesh |
| `^SF` | Collision | Bullet-only collision (shoot-through for players) |
| `^SK` | Collision | Sphere Dummy collision |
| `!` | Auxiliary | Helper/auxiliary object (not rendered) |
| `@` | Effect | Effect sphere (water, slowdown zones) |
| `>` | LOD | Hidden LOD level (can stack: `>>`, `>>>`) |

### Effect Sphere Format
`@[material][slowdown]-name`
- material: 4-char surface code (WATR, GRAS, etc.)
- slowdown: 0-9 (movement slowdown factor)
- Example: `@WATR5-pond` = water effect with 50% slowdown

### Material Colors and Properties
From DumpPteroLayer function analysis:
- `mat_diffuse` - RGB diffuse color
- `mat_ambient` - RGB ambient color
- `mat_specular` - RGB specular color
- `mat_self_illum` - RGB self-illumination
- `mat_opacity` - 0-100 opacity
- `mat_opacity_falloff` - opacity falloff
- `mat_glossiness` - 0-100 glossiness
- `mat_spec_level` - 0-100 specular level

### Water/Glass Properties
- `is_water` - water material flag
- `is_glass` - glass material flag
- `water_env_blend` - environment blend factor
- `water_alpha_angle` - alpha angle for water
- `water_sharpness` - XYZ sharpness values
- `water_shifting_xy` - XY shifting for water animation
- `water_shifting_uv` - UV shifting for water animation

### Physics User Properties (Complete List from PDF)
Stored in object's User Defined Properties (chunk 0x34):

| Property | Type | Values | Description |
|----------|------|--------|-------------|
| `Phy_colshp` | int | 0-3 | Collision shape: 0=mesh, 1=box, 2=sphere, 3=capsule |
| `Phy_misshp` | int | 0-3 | Missile collision shape |
| `Phy_defmat` | str | 4 chars | Default physics material (e.g., "WOOD", "METL") |
| `Phy_weight` | float | | Object weight in kg |
| `Phy_density` | float | | Material density |
| `Phy_moment` | float | | Moment of inertia |
| `Phy_status` | int | 0-2 | 0=static, 1=dynamic, 2=kinematic |

### LOD Properties (from PDF)
| Property | Type | Description |
|----------|------|-------------|
| `Lod` | float | LOD switch distance (e.g., `Lod=50`) |
| `LastLodAlpha` | bool | Last LOD has alpha fade-out |
| `ClipDist` | float | Object clip distance |
| `Dol` | float | Distance of LOD |
| `DolNoAlpha` | bool | DOL without alpha |
| `AlphaMult` | float | Alpha multiplier |

### Animation Properties (from PDF)
| Property | Format | Description |
|----------|--------|-------------|
| `TexMove` | X,Y | UV animation speed |
| `TexPing` | flag | Ping-pong texture animation |
| `Wobble` | X,Y,Z | Vertex wobble animation amplitude |
| `Lighting` | flag | Dynamic lighting enabled |
| `Smooth` | flag | Smooth shading |

### Texture Layer Flags (PteroLayer)
```
0x000001 = tileU
0x000002 = tileV
0x000010 = mipmap
0x000020 = crop
0x000100 = move (UV animation)
0x100000 = envType (environment mapping)
0x400000 = lmApplyLight (lightmap applies lighting)
0x800000 = overlayMultitex (overlay multitexture)
```

---

## Features for Future Implementation

### Joint Chunk (0x65 = 101)
Physics constraints for animated objects (doors, wheels, etc.)

#### Structure
```
Offset 0:   chunk_type (101)
Offset 4:   size
Offset 8:   version (2)
Offset 12:  SPIN_ON (int) - rotation enabled
Offset 16:  SPIN_MIN_ANGLE (float) - minimum rotation angle
Offset 20:  SPIN_MAX_ANGLE (float) - maximum rotation angle
Offset 24:  friction (float)
Offset 28:  collide (int)
Offset 32:  CONE_ON (int) - cone constraint enabled
Offset 36:  CNE_ANG (float) - cone angle

// Plane constraints (4 total: ZX_A, ZX_B, ZY_A, ZY_B)
// Each plane has 6 values (24 bytes):
Offset 40:  PLANE_ZX_A_ON (int)
Offset 44:  PLANE_ZX_A_TYPE (int)
Offset 48:  PLANE_ZX_A_OFFSET (float)
Offset 52:  PLANE_ZX_A_LEAN (float)
Offset 56:  PLANE_ZX_A_POINT_X (float)
Offset 60:  PLANE_ZX_A_POINT_Y (float)

Offset 64:  PLANE_ZX_B_ON (int)
Offset 68:  PLANE_ZX_B_TYPE (int)
Offset 72:  PLANE_ZX_B_OFFSET (float)
Offset 76:  PLANE_ZX_B_LEAN (float)
Offset 80:  PLANE_ZX_B_POINT_X (float)
Offset 84:  PLANE_ZX_B_POINT_Y (float)

Offset 88:  PLANE_ZY_A_ON (int)
Offset 92:  PLANE_ZY_A_TYPE (int)
Offset 96:  PLANE_ZY_A_OFFSET (float)
Offset 100: PLANE_ZY_A_LEAN (float)
Offset 104: PLANE_ZY_A_POINT_X (float)
Offset 108: PLANE_ZY_A_POINT_Y (float)

Offset 112: PLANE_ZY_B_ON (int)
Offset 116: PLANE_ZY_B_TYPE (int)
Offset 120: PLANE_ZY_B_OFFSET (float)
Offset 124: PLANE_ZY_B_LEAN (float)
Offset 128: PLANE_ZY_B_POINT_X (float)
Offset 132: PLANE_ZY_B_POINT_Y (float)

Offset 136: OBJECT_A name (null-terminated string)
Followed by: OBJECT_B name (null-terminated string)
```

#### User Properties for Joints
Set in 3DS Max Object Properties:
- `OBJECT_A` - First object reference
- `OBJECT_B` - Second object reference
- `friction` - Friction coefficient
- `collide` - Enable collision
- `SPIN_ON` - Enable rotation
- `SPIN_MIN_ANGLE` - Minimum rotation angle (degrees)
- `SPIN_MAX_ANGLE` - Maximum rotation angle (degrees)
- `CONE_ON` - Enable cone constraint
- `CNE_ANG` - Cone angle (degrees)
- `PLANE_*` - Plane constraint properties

### Special Object Prefixes
- `^K` - Collision mesh (linked to parent object)
- `^SF` - Bullet-only collision
- `^SK` - Sphere Dummy collision
- `!` - Auxiliary/helper object
- `@` - Effect sphere
- `>` - Hidden object / LOD level (not rendered in editor)
- `!_zaklad` - Base/root object marker
- `glass_dummy` - Glass helper object

### Transparency Types (from PDF)
| Type | Name | Description | Blender Equivalent |
|------|------|-------------|-------------------|
| 0 | None | No transparency | OPAQUE |
| 1 | Additive | Additive blending | BLEND + Emission |
| 2 | Alpha | Standard alpha | BLEND |
| 3 | AlphaRef | Alpha with reference | CLIP |
| 4 | AlphaRef2 | Alpha with 2nd reference | HASHED |

### PRM_ Material Properties
Found in string table:
- `PRM_DIFF2_TILE` - Diffuse 2 tiling
- `PRM_MIPMAP_OVERLAY` - Mipmap for overlay
- `PRM_LIGHT` - Light property
- `PRM_MIPMAP` - Mipmap enabled
- `PRM_GRASS_TYPE` - Grass type code
- `PRM_GROW_TYPE` - Grow/vegetation type code
- `PRM_TRANSPARENT_TYPE` - Transparency type
- `PRM_COLLISION_TYPE` - Collision material type
- `PRM_ENVIRONMENT_TYPE` - Environment mapping type

---

## Chunk Types Reference

| Chunk ID | Hex | Name | Description |
|----------|-----|------|-------------|
| 0x01 | OBJECT | Object/Node | Scene node container |
| 0x30 | MODEL | Model | Mesh container |
| 0x31 | MESH | Mesh | Single mesh with material |
| 0x32 | VERTICES | Vertices | Vertex data |
| 0x33 | FACES | Faces | Face/triangle data |
| 0x34 | PROPERTIES | Properties | User properties (INI format) |
| 0x35 | TRANSFORM | Transform | Translation, rotation, scale, matrix |
| 0x40 | BBOX | BBox | Bounding sphere radius |
| 0x65 | JOINT | Joint | Physics constraint (NOT YET IMPLEMENTED) |
| 0x70 | INFO | Info | Author, comment, face count |
| 0x1000 | MATERIAL_LIST | Material List | Material container |
| 0x1001 | STANDARD_MATERIAL | Standard | 3DS Max Standard material |
| 0x1002 | PTEROMAT | PteroMat | Ptero-Engine material |
| 0x1004 | PTEROLAYER | PteroLayer | Advanced layered material |

---

## Implementation Notes

### Collision Mesh Workflow
1. Create low-poly collision mesh
2. Name it with `^K` prefix (e.g., `^KMyObject`)
3. Parent to main render mesh
4. Set `Phy_defmat` property on collision mesh
5. Export will link collision to parent

### Joint Workflow (Future)
1. Create two objects to constrain
2. Add joint properties to one object
3. Set `OBJECT_A` and `OBJECT_B` references
4. Configure rotation/cone/plane constraints
5. Export creates Joint chunk (0x65)

### Material Type Detection
Materials are identified by:
1. `bes_material_type` custom property
2. Chunk type during import (0x1001, 0x1002, 0x1004)

---

## Source References
- Function: `sub_89790C0` - Collision object processing
- Function: `sub_897C370` - Joint property export
- Function: `DumpPteroLayer` (0x897FAF0) - PteroLayer material dump
- Strings at: 0x898A000+ region
