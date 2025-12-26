

## Session: 2025-12-04

### Overview
Fixed critical bugs in both importer and exporter for BES file format.

---

## IMPORTER FIXES

### 1. User Defined Properties - Raw Text Display

**Problem:** Complex UI panels (LOD, Wobble, Lighting) weren't syncing with actual BES properties. Properties stored in `obj['bes_is_lod']` but UI read from `obj.bes.is_lod` (different systems).

**Solution:** Simplified to raw text display like original 3ds Max plugin.

**Files Changed:**
- `vietcong_bes/importers/bes_importer.py` (line 759-761)
- `vietcong_bes/ui/__init__.py` (line 645-672)

**Code:**
```python
# Importer: Store raw text
if bes_node.properties.raw_text:
    obj['bes_user_properties'] = bes_node.properties.raw_text

# UI Panel: Display raw text
class BES_PT_user_properties(bpy.types.Panel):
    bl_label = "User Defined Properties"

    def draw(self, context):
        props_text = context.object.get('bes_user_properties', '')
        if props_text:
            box = self.layout.box()
            for line in props_text.split('\n'):
                if line.strip():
                    box.label(text=line)
```

### 2. LOD Distance Not Loading

**Problem:** BES files can have multiple `Lod=` lines (e.g., `Lod=20\nLod=-1`). The `properties['Lod']` dict only kept the LAST value (-1), but `lod_distances` list kept ALL values.

**Solution:** Use `lod_distances` list instead of `properties['Lod']`.

**File:** `vietcong_bes/importers/bes_importer.py` (line 750-757)

**Code:**
```python
if bes_node.properties.lod_distances:
    for lod_dist in bes_node.properties.lod_distances:
        if lod_dist > 0:
            obj['bes_lod_distance'] = lod_dist
            break  # Use first positive value
```

### 3. Transform Order

**Problem:** Uncertain whether BES stores world or local coordinates.

**Solution:** Keep original order: set parent first, then apply transform.

---

## EXPORTER FIXES

### 1. MATERIAL_LIST Chunk Size Bug

**Problem:** Material list chunk header had hardcoded size of 12 bytes. Materials were written AFTER the chunk instead of INSIDE it.

**Symptom:**
```
Unknown material found! BlockID: 0x09
Unknown block found! BlockID: 0x00001002
```

**Root Cause:**
```python
# WRONG - hardcoded size, materials outside chunk:
w.write_chunk_header(ChunkType.MATERIAL_LIST, 4 + 8)
w.write_uint32(len(materials))
for mat in materials:
    self._write_pteromat_to_builder(w, mat)  # Written to parent!
```

**Solution:** Use ChunkBuilder to calculate correct size.

**File:** `vietcong_bes/core/bes_writer.py` (line 155-179)

**Code:**
```python
def _write_material_list_to_builder(self, w: BinaryWriter, materials: List[BESMaterial]):
    mat_list_builder = ChunkBuilder(ChunkType.MATERIAL_LIST)
    mlw = mat_list_builder.writer

    mlw.write_uint32(len(materials))

    for mat in materials:
        if isinstance(mat, BESPteroMat):
            self._write_pteromat_to_builder(mlw, mat)  # Inside chunk!
        # ...

    w.write(mat_list_builder.build())  # Correct size calculated
```

### 2. TRANSFORM Chunk Extra Byte

**Problem:** Exporter wrote 101 bytes for transform chunk, but original format is exactly 100 bytes.

**Root Cause:** Extra `write_uint8(0)` wobble flag that doesn't exist in original format.

**IDA Analysis (BesExport.dlu @ 0x8978105):**
```asm
mov dword ptr [ebp+0], 35h   ; Chunk type = 0x35 (TRANSFORM)
mov dword ptr [ebp+4], 6Ch   ; Chunk size = 108 bytes (8 header + 100 data)
```

**Original Format (100 bytes data):**
- translation: 12 bytes (3 floats)
- rotation: 12 bytes (3 floats)
- scale: 12 bytes (3 floats)
- matrix: 64 bytes (4x4 matrix)

**Solution:** Remove wobble flag byte.

**File:** `vietcong_bes/core/bes_writer.py` (line 522-565)

**Code:**
```python
def _write_transform_to_builder(self, w: BinaryWriter, transform):
    trans_builder = ChunkBuilder(ChunkType.TRANSFORM)
    tw = trans_builder.writer

    # NO wobble flag - directly write data
    tw.write_vec3(transform.translation)
    tw.write_vec3(transform.rotation)
    tw.write_vec3(transform.scale)
    tw.write_matrix4x4(transform.matrix or identity)

    w.write(trans_builder.build())
```

---

## IDA ANALYSIS SUMMARY

**Database:** BesExport.dlu (3ds Max 7 plugin)

### Key Functions Found:
- `DumpPteroMat` @ 0x8981040 - Writes PTEROMAT (0x1002) chunks
- `DumpPteroLayer` @ 0x897FAF0 - Writes PTEROLAYER (0x1004) chunks
- `DumpStdMaterial` @ 0x8981D60 - Writes STANDARD_MATERIAL (0x1001) chunks
- Transform writing @ 0x8978090 - Writes TRANSFORM (0x35) chunks

### Chunk Format Confirmed:
- PTEROMAT: 0x1002
- TRANSFORM: 0x35, size 108 bytes (8 header + 100 data)
- No wobble flag in transform data

---

## TEST FILES

| File | Purpose |
|------|---------|
| `tests/HAJZLIK/G17_HAJZLIK.BES` | Building with LOD doors |
| `tests/stromy/*.BES` | Trees with Lod, Islod, ClipDist, Wobble properties |

### Properties Found in Test Files:
- `Lod=20`, `Lod=-1` (multiple values on same object)
- `Islod=1`
- `ClipDist=15`
- `Wobble=0.1,0.02,0.4,0.3`
- `Lighting=0.5,0.5,0.5,0.02,0.02,0.02`
- `LastLodAlpha=1`

---

## COORDINATE SYSTEMS

**BES (DirectX):** Left-handed, Y-up, Z-forward
- X = right
- Y = up
- Z = forward

**Blender:** Right-handed, Z-up, Y-forward
- X = right
- Y = forward
- Z = up

**Conversion:** `(x, y, z) -> (x, z, y)`

---

## Session: 2025-12-25

### EXPORTER FIXES

### 1. KRITICKÁ: child_count jako float místo uint32

**Problém:** child_count se zapisoval jako `write_float()`, ale engine čte `read_uint32()`.

**Symptom:** Hra crashuje při načítání exportovaného .bes souboru.

**Root Cause:**
```python
# ŠPATNĚ:
w.write_float(float(child_count))  # Float 2.0 = 0x40000000

# SPRÁVNĚ:
w.write_uint32(child_count)  # Uint32 2 = 0x00000002
```

**Soubor:** `vietcong_bes/core/bes_writer.py` (řádky 139 a 424)

### 2. UV handling - ztráta dat pro sdílené vertexy

**Problém:** Blender má UV per-loop (per triangle corner), ale BES formát má UV per-vertex. Původní kód ukládal jen první UV pro každý vertex.

**Symptom:** Špatné textury na objektech s UV seams.

**Root Cause:**
```python
# ŠPATNĚ - ignoruje UV pro další trojúhelníky:
if not bes_mesh.vertices[vert_idx].uvs:
    bes_mesh.vertices[vert_idx].uvs.append(bes_uv)
```

**Řešení:** Přepsána `_convert_mesh()` - vertexy se nyní duplikují když mají různé UV.

**Soubor:** `vietcong_bes/exporters/bes_exporter.py` (řádky 444-539)

### 3. Transformační matice nebyla počítána

**Problém:** Transform chunk obsahoval pouze position/rotation/scale, ale 4x4 matice byla vždy identity.

**Řešení:** Přidán výpočet matice z `obj.matrix_local` s konverzí pomocí `blender_matrix_to_bes()`.

**Soubor:** `vietcong_bes/exporters/bes_exporter.py` (řádky 414-424)

### 4. INFO chunk na špatném místě (způsobuje crash)

**Problém:** INFO chunk (0x70) se zapisoval na top-level před OBJECT chunkem.

**Symptom:** Hra crashuje - engine očekává OBJECT (0x0001) jako první chunk po preview.

**Hex analýza:**
```
ORIGINÁL offset 0x3010:  01 00 00 00 = OBJECT
EXPORTED offset 0x3010:  70 00 00 00 = INFO  ← ŠPATNĚ!
```

**Řešení:** Odstraněn zápis INFO chunku z top-level.

**Soubor:** `vietcong_bes/core/bes_writer.py` (řádky 74-76)

### 5. Model otočený při reimportu

**Problém:** Exporter konvertoval souřadnice (Y↔Z swap), ale importer nekonvertoval.

**Symptom:** Import → Export → Reimport = model otočený na bok.

**Root Cause:**
- Importer (řádek 847): `all_verts.append(vert.position)` - raw coords
- Exporter (řádek 505): `pos = blender_to_bes_coords(...)` - konvertované

**Řešení:** Exporter nyní používá raw souřadnice bez konverze.

**Soubor:** `vietcong_bes/exporters/bes_exporter.py` (řádky 503-509, 414-424)

---

## TODO / REMAINING ISSUES

- [ ] Test export -> import roundtrip
- [ ] Verify material textures export correctly
- [ ] Test in Ptero-Engine-II game
