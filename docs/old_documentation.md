# BES Format - Complete Specification

## Overview
BES (Binary Export Scene / BenyErikSolitude) is a hierarchical chunk-based 3D model format used by the Ptero-Engine-II in Vietcong (2003). It supports meshes, materials, LODs, animations, skeletal data, and scene hierarchy.

**Engine:** Ptero-Engine-II  
**Games:** Vietcong (2003), Vietcong 2 (2005)  
**Primary Parser:** logs.dll, BES_Load function at 0x1000C6C0

---

## File Structure

### Complete File Layout
```
BES File
├── Header (16 bytes)
├── Preview Image (12288 bytes)
└── Data Chunks (variable)
```

---

## Header (16 bytes)

```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     CHAR[4]   Signature: "BES\0" (0x42 0x45 0x53 0x00)
0x04    4     CHAR[4]   Version (ASCII string)
0x08    4     UINT32LE  Exporter/MaxSDKVersion
0x0C    4     UINT32LE  Unknown/Reserved
```

**Supported Versions:**
- `0x30303034` = "0004" (version 4)
- `0x30303035` = "0005" (version 5)
- `0x30303036` = "0006" (version 6)
- `0x30303037` = "0007" (version 7)
- `0x30303038` = "0008" (version 8) - **most common**
- `0x30313030` = "0010" (version 10)

**Exporter Types (MaxSDKVersion):**
- `0x00000000` = AutoSelect
- `0x17700d00` = 3DS Max 6
- `0x1b580f00` = 3DS Max 7
- `0x1f401100` = 3DS Max 8

---

## Preview Image (12288 bytes)

**Format:** 64x64 pixel preview image  
**Pixel Format (3 bytes per pixel):**
```
Offset  Size  Type   Description
------  ----  -----  -----------
0x00    1     UINT8  Green channel
0x01    1     UINT8  Blue channel
0x02    1     UINT8  Red channel
```

**Total Size:** 64 × 64 × 3 = 12,288 bytes

---

## Data Block - Chunk Structure

All data after preview is organized in chunks:

```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     UINT32LE  Chunk Type ID
0x04    4     UINT32LE  Chunk Data Size (excluding 8-byte header)
0x08    N     BYTE[]    Chunk Data
```

---

## Scene Hierarchy Chunks

### 0x01 - Object/Node
Main scene node containing object hierarchy and properties.

**Structure:**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     FLOAT     Child count (may be in 0x70 wrapper)
0x04    4     UINT32LE  Name length (includes NULL)
0x08    N     CHAR[]    Node name (NULL-terminated)
N+8     ...   CHUNK[]   Child chunks (recursive)
```

**Node Structure in Memory (s_NOD - 160 bytes):**
```c
struct s_NOD {
    s_NOD*  parent;          // +0x00 (0)   Parent node pointer
    void*   first_child;     // +0x04 (4)   First child or wobble data
    char    name[64];        // +0x08 (8)   Node name
    QWORD   hash;            // +0x50 (80)  Name hash (64-bit)
    DWORD   flags;           // +0x58 (88)  Object flags
    FLOAT   clip_distance;   // +0x5C (92)  Clip distance squared
    FLOAT   bbox_radius;     // +0x60 (96)  Bounding box radius
    FLOAT   bbox_radius_sq;  // +0x64 (100) Bounding box radius squared
    void**  children_array;  // +0x68 (104) Array of child pointers
    FLOAT   child_count;     // +0x6C (108) Number of children
    s_NOD*  entity_parent;   // +0x70 (112) Entity parent
    void*   script;          // +0x78 (120) Script pointer
    DWORD   type;            // +0x7C (124) Node type
    void*   lod_data;        // +0x80 (128) LOD information
    void*   transform;       // +0x84 (132) Transform matrix
    // ... more fields up to 160 bytes
};
```

**Node Types (offset +0x7C):**
- 4 = ISKE (skeletal animation node)
- 6 = Static mesh
- 18 = LOD group

**Flags (offset +0x58):**
- `0x800000` = Hidden/disabled node (name starts with '>')
- `0x1000000` = Has LOD data
- `0x10000` = Has texture layer 1 (diffuse)
- `0x20000` = Has texture layer 2 (opacity)
- `0x40000` = Has lightmap
- `0x80000` = Has detail map
- `0x100000` = Has bump map
- `0x200000` = Has specular map
- `0x400000` = Has glow/self-illumination map

**Name Hash Algorithm (64-bit):**
```python
def calculate_hash(name):
    hash_val = 0
    for char in name:
        c = ord(char)
        if c >= ord('a') and c <= ord('z'):
            c = c - 32  # Convert to uppercase
        
        if c < 0x20 or c >= 0x60:
            continue  # Skip invalid characters
        
        # Hash formula: hash = (hash - 2) * 16 + char
        hash_val = ((hash_val - 2) * 16 + c) & 0xFFFFFFFFFFFFFFFF
    
    return hash_val
```

---

### 0x30 - Model Container
Declares mesh group/model with child meshes.

**Structure:**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     UINT32LE  Mesh children count
```

**Child Chunks:**
- Mesh (0x31) - any number
- Properties (0x34) - 1 optional
- Transformation (0x35) - 1 optional
- Unknown 0x36 - 1 optional

---

### 0x31 - Mesh Reference
Links mesh to material and contains mesh data.

**Structure:**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     UINT32LE  Material index (-1 = no material, 0xFFFFFFFF)
```

**Required Child Chunks:**
- Vertices (0x32) - 1
- Faces (0x33) - 1

---

### 0x32 - Vertices
Mesh vertex data with positions, normals, and UV coordinates.

**Structure:**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     UINT32LE  Vertex count
0x04    4     UINT32LE  Vertex structure size (24 + 8*tex_count)
0x08    4     UINT32LE  Flags (D3DFVF format)
0x0C    N     VARIES    Vertex data array
```

**D3DFVF Flags (must all be set):**
- `D3DFVF_XYZ` (0x002) = Position (XYZ)
- `D3DFVF_NORMAL` (0x010) = Normal vector
- `D3DFVF_TEXn` (0x000 - 0x800) = Number of texture coordinate sets

**Vertex Structure (based on D3DVERTEX):**
```
Offset  Size  Type          Description
------  ----  ------------  -----------
0x00    4     FLOAT32LE     Position X
0x04    4     FLOAT32LE     Position Y
0x08    4     FLOAT32LE     Position Z
0x0C    4     FLOAT32LE     Normal X
0x10    4     FLOAT32LE     Normal Y
0x14    4     FLOAT32LE     Normal Z
0x18    8*N   FLOAT32LE[]   UV coordinates (U,V pairs for each texture)
```

**Size Calculation:**
- Base size: 24 bytes (position + normal)
- Per texture: +8 bytes (U + V coordinates)
- Total: 24 + (8 × texture_count)

---

### 0x33 - Faces
Triangle face indices referencing vertex array.

**Structure:**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     UINT32LE  Face count
0x04    N     UINT32LE  Face data (3 indices per face)
```

**Face Structure (12 bytes each):**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     UINT32LE  Vertex index A
0x04    4     UINT32LE  Vertex index B
0x08    4     UINT32LE  Vertex index C
```

**Note:** All faces are triangles. Indices reference the vertex array in chunk 0x32.

---

### 0x34 - Properties (User Defined)
Object properties as INI-style text from 3DS Max user properties.

**Structure:**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     UINT32LE  String length (includes NULL)
0x04    N     CHAR[]    INI string data (NULL-terminated)
```

**Common Properties:**
```ini
Lighting=1,0.5,0,0,0        # Lighting parameters (5 floats)
Wobble=0.05,0.05,0.05,5,5,5 # Vegetation wind effect (amplitude, frequency)
Lod=15                      # LOD distance threshold (meters)
Lod=100                     # Multiple LOD levels possible
LastLodAlpha=11             # Alpha blending for final LOD level
Clipdist=X                  # Custom clip distance override
```

**Wobble Format:**
- First 3 values: Amplitude (X, Y, Z)
- Last 3 values: Frequency (X, Y, Z)

---

### 0x35 - Transformation
Object transformation matrix and decomposed vectors.

**Structure:**
```
Offset  Size  Type          Description
------  ----  ------------  -----------
0x00    1     BYTE          Has wobble data flag (0 or 1)
0x01    12    FLOAT32LE[3]  Translation vector (X, Y, Z)
0x0D    12    FLOAT32LE[3]  Rotation vector (radians, X, Y, Z)
0x19    12    FLOAT32LE[3]  Scale vector (X, Y, Z)
0x25    64    FLOAT32LE[16] Transform matrix 4×4 (D3DMATRIX)
```

**Total Size:** 105 bytes (0x69)

**Note:** Matrix may contain calculation errors in some exported files. Prefer using decomposed translation/rotation/scale vectors.

**Wobble Parameters (if flag = 1):**
```
Offset  Size  Type          Description
------  ----  ------------  -----------
0x01    12    FLOAT32LE[3]  Amplitude (X, Y, Z)
0x0D    12    FLOAT32LE[3]  Frequency (X, Y, Z)
0x19    12    FLOAT32LE[3]  Phase offset (X, Y, Z)
```

Then followed by 4×4 matrix at 0x25.

---

### 0x36 - Bounding Box
Object bounding sphere radius.

**Structure:**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     FLOAT32LE Radius
```

**Storage:** Radius is stored as-is at node offset +0x60, and squared at offset +0x64.

---

### 0x38 - Unknown Container
Purpose unclear. Contains properties, transformation, and recursive data.

**Structure:**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    N     VARIES    Unknown binary data
```

**Child Chunks:**
- Object (0x01) - 0 or 1
- Properties (0x34) - 1
- Transformation (0x35) - 1
- Unknown 0x38 - 1 (recursive)

---

### 0x50 (80) - ISKE Node
Skeletal animation node with bones and hierarchy.

**Structure:**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     FLOAT     Bone/child count
0x04    4     UINT32LE  Name length
0x08    N     CHAR[]    Node name
...     ...   CHUNK[]   Sub-chunks (recursive bones)
```

Sets node type to 4 (ISKE) and creates skeleton structure.

---

### 0x51 (81) - Mesh Chunk
Contains mesh data parsed by sub_1008F8D0.

Stores mesh pointer at `node->lod_data->data[64]`.

---

### 0x54 (84) - Unknown
Skip 28 bytes. Purpose unknown.

---

### 0x70 (112) - Info Block
File metadata with author, comment, and statistics.

**Structure:**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     UINT32LE  Author length (max 64)
0x04    4     UINT32LE  Comment length
0x08    4     UINT32LE  Total face count
0x0C    64    CHAR[64]  Author name (zero-padded)
0x4C    N     CHAR[]    Comment text (NULL-terminated)
```

**Note:** Author field is fixed 64 bytes, zero-padded. Remaining bytes filled with zeros.

---

## Material Chunks

### 0x1000 (4096) - Material List Header
Declares number of materials in scene.

**Structure:**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     UINT32LE  Material count
```

Creates array of materials (120 bytes each).

**Material Structure in Memory (120 bytes):**
```c
struct Material {
    FLOAT   id;              // +0x00 Material ID
    DWORD   shader_type;     // +0x04 Shader type (0-5)
    char    diffuse[32];     // +0x08 Diffuse texture name
    char*   opacity;         // +0x28 Opacity texture (malloc)
    char*   bump;            // +0x2C Bump map (malloc)
    char*   detail;          // +0x30 Detail map (malloc)  
    char*   specular;        // +0x34 Specular map (malloc)
    char*   glow;            // +0x38 Glow/emission map (malloc)
    DWORD   texture_id;      // +0x40 Loaded texture ID
    DWORD   opacity_id;      // +0x44 Loaded opacity ID
    DWORD   bump_id;         // +0x48 Loaded bump ID
    DWORD   detail_id;       // +0x50 Loaded detail ID
    DWORD   specular_id;     // +0x54 Loaded specular ID
    DWORD   flags;           // +0x5C Material flags
    FLOAT   detail_amount;   // +0x58 Detail map amount (0-1)
    FLOAT   detail_scale;    // +0x60 Detail map scale
    FLOAT   opacity_amount;  // +0x64 Opacity multiplier (0-1)
    WORD    properties[4];   // +0x68 Additional properties
    // +0x70-0x77 reserved (8 bytes)
};
```

**Shader Types (offset +0x04):**
- 0 = Standard (default)
- 1 = Glass/transparent (#1)
- 2 = Lightmap (#3)
- 3 = Emissive/glowing (#0)
- 4 = Detail map (#2)
- 5 = Special effects (#4)

Derived from texture name prefix: `#0`, `#1`, `#2`, `#3`, `#4`

---

### 0x1001 (4097) - Standard Material (3DS Max)
Standard material from 3DS Max with multiple texture maps.

**Structure:**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     FLOAT     Material ID
0x04    4     FLOAT     Unknown/Reserved
0x08    4     UINT32LE  Map type bitfield
```

**Map Type Flags (field at +0x08):**

**UV Order in Vertices vs. Flag Order:**  
The UV coordinates in vertex data are ordered differently than the flag bits!

**UV Order in Vertex Data (0x32):**
1. Ambient Color (flag 0x008)
2. Diffuse Color (flag 0x001)
3. Specular Color (flag 0x010)
4. Specular Level (flag 0x020)
5. Glossiness (flag 0x040)
6. Self-Illumination (flag 0x080)
7. Filter Color (flag 0x200)
8. Bump (flag 0x004)
9. Reflection (flag 0x400)
10. Refraction (flag 0x800)
11. Displacement (flag 0x002)

**Note:** Opacity texture can be created in 3DS Max but is **never exported** to BES. Flag 0x100 is unused (possibly intended for opacity).

**Map Structure (for each enabled flag):**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     UINT32LE  Name length (includes NULL)
0x04    4     UINT32LE  Coordinates flags
0x08    N     CHAR[]    Texture filename
```

**Coordinates Flags:**
- Bit 0: U tile
- Bit 1: V tile
- Bit 2: U mirror
- Bit 3: V mirror

**Note:** Tile and mirror cannot be used simultaneously on the same axis.

Maps are ordered **by flag value** (not UV order) in the chunk data.

---

### 0x1002 (4098) - PteroMat Material
Enhanced material format specific to Ptero-Engine.

**Structure:**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     UINT32LE  Sides (0=1-sided, 1=2-sided)
0x04    4     UINT32LE  Texture type bitfield
0x08    4     CHAR[4]   Collision Material (2 bytes + 2 zeros)
0x0C    4     UINT32LE  Transparency type
0x10    4     CHAR[4]   Vegetation type (2 bytes + 2 zeros)
0x14    4     UINT32LE  Name length
0x18    N     CHAR[]    Material name
```

**Texture Type Flags (field at +0x04):**

**UV Order in Vertex Data:**
1. Diffuse #1 - Ground (flag 0x010000)
2. Diffuse #3 - Overlay/Overlay Multitexture (flags 0x040000 / 0x800000)
3. Diffuse #2 - Multitexture (flag 0x020000)
4. Environment #1 (flag 0x100000)
5. LightMap / LightMap Engine Lights (flags 0x080000 / 0x400000)

**Extended Flags:**
- `0x010000` = Diffuse #1 (Ground)
- `0x020000` = Diffuse #2 (Multitexture)
- `0x040000` = Diffuse #3 (Overlay)
- `0x080000` = LightMap
- `0x100000` = Environment #1
- `0x200000` = Environment #2 (unused, never exported)
- `0x400000` = LightMap Engine Lights
- `0x800000` = Overlay Multitexture

**Collision Material (2 bytes):**
Identifies material type for collision physics.

**Transparency Types:**
- `0x202D` = None (opaque)
- `0x3023` = #0 - transparent, zbufwrite, sort
- `0x3123` = #1 - transparent, zbufwrite, sort, 1-bit alpha
- `0x3223` = #2 - translucent, no_zbufwrite, sort
- `0x3323` = #3 - transparent, zbufwrite, nosort, 1-bit alpha
- `0x3423` = #4 - translucent, add with background, no_zbufwrite, sort

**Vegetation Type (2 bytes):**
- 0 = Grow Type
- 1 = Grass Type

**Texture Map Structure (for each enabled flag):**
```
Offset  Size  Type      Description
------  ----  --------  -----------
0x00    4     UINT32LE  Coordinates config
0x04    4     UINT32LE  Name length
0x08    N     CHAR[]    Texture filename
```

**Coordinates Config (4 bytes):**
- Upper 2 bytes: Map type flag (same as texture type flags above)
- Lower 2 bytes: Tiling flags
  - Bit 0: U tile
  - Bit 1: V tile
  - Bit 4: Unknown flag

**Note:** Unlike Standard materials, PteroMat texture entries contain their type in the coordinates field, so they are **not required** to be ordered by flag value.

---

## Texture Name Processing

```python
def process_texture_name(name):
    name = name.lower()
    
    # Handle animated textures (.ifl)
    if name.endswith('.ifl'):
        return '*' + name  # Prefix with asterisk
    
    # Strip extension for others
    name = name.rsplit('.', 1)[0]
    
    # Detect shader type from prefix
    shader_type = 0
    if name.startswith('#'):
        shader_map = {
            '#0': 3,  # Emissive
            '#1': 1,  # Glass/transparent
            '#2': 4,  # Detail map
            '#3': 2,  # Lightmap
            '#4': 5   # Special effects
        }
        prefix = name[:2]
        shader_type = shader_map.get(prefix, 0)
    
    return name, shader_type
```

**IFL Files:** Animated textures use `.ifl` extension. The .ifl file contains a list of frame filenames.

---

## Parsing Algorithm

### Main Loop
```python
def parse_bes(file_path):
    with open(file_path, 'rb') as f:
        # Read header
        magic = read_dword(f)
        if magic != 0x00534542:  # "BES\0"
            raise ValueError("Invalid BES magic")
        
        version = read_chars(f, 4)
        exporter = read_dword(f)
        reserved = read_dword(f)
        
        # Read preview (skip or process)
        preview_data = f.read(12288)
        
        # Parse data chunks
        root_node = None
        while True:
            chunk_start = f.tell()
            chunk_type = read_dword(f)
            chunk_size = read_dword(f)
            
            if chunk_type == 0x70:  # Info block
                parse_info(f, chunk_size)
            elif chunk_type == 0x01:  # Object/Node
                root_node = parse_node(f, chunk_size)
            else:
                f.seek(chunk_start + 8 + chunk_size)
            
            if f.tell() >= file_size:
                break
        
        return root_node
```

### Recursive Node Parsing
```python
def parse_node(f, size):
    start_pos = f.tell()
    end_pos = start_pos + size
    
    # Read node header
    child_count = read_float(f)
    name_len = read_dword(f)
    name = read_string(f, name_len)
    
    # Create node
    node = Node()
    node.name = name
    node.hash = calculate_hash(name)
    node.children = []
    
    # Parse child chunks
    while f.tell() < end_pos:
        chunk_type = read_dword(f)
        chunk_size = read_dword(f)
        chunk_data_start = f.tell()
        
        if chunk_type == 0x01:    # Child node
            child = parse_node(f, chunk_size)
            node.children.append(child)
        elif chunk_type == 0x30:  # Model
            parse_model(f, node, chunk_size)
        elif chunk_type == 0x31:  # Mesh
            parse_mesh(f, node, chunk_size)
        elif chunk_type == 0x32:  # Vertices
            parse_vertices(f, node, chunk_size)
        elif chunk_type == 0x33:  # Faces
            parse_faces(f, node, chunk_size)
        elif chunk_type == 0x34:  # Properties
            parse_properties(f, node, chunk_size)
        elif chunk_type == 0x35:  # Transformation
            parse_transformation(f, node, chunk_size)
        elif chunk_type == 0x36:  # Bounding box
            parse_bbox(f, node, chunk_size)
        elif chunk_type == 0x1000: # Material list
            parse_material_list(f, node, chunk_size)
        elif chunk_type == 0x1001: # Standard material
            parse_standard_material(f, node, chunk_size)
        elif chunk_type == 0x1002: # PteroMat
            parse_pteromat(f, node, chunk_size)
        else:
            # Skip unknown chunk
            f.seek(chunk_data_start + chunk_size)
        
        # Ensure we're at the end of this chunk
        f.seek(chunk_data_start + chunk_size)
    
    return node
```

---

## Implementation Notes

### For Importers (Blender, etc.):

1. **File Reading:**
   - Read 16-byte header, validate magic
   - Skip or read 12288-byte preview
   - Parse chunks recursively

2. **Scene Hierarchy:**
   - Create object/empty for each node (chunk 0x01)
   - Maintain parent-child relationships
   - Handle hidden nodes (name starts with '>')

3. **Materials:**
   - Build material list from chunk 0x1000
   - Parse Standard (0x1001) or PteroMat (0x1002)
   - Load textures, handle .ifl animated textures
   - Map shader types to modern material systems

4. **Meshes:**
   - Parse vertices (0x32) with proper D3DFVF interpretation
   - Parse faces (0x33) as triangles
   - Assign material by index (0x31)
   - Apply UV coordinates (order is crucial!)

5. **Transformations:**
   - Apply translation, rotation (radians), scale
   - Matrix may have errors - prefer decomposed values
   - Handle wobble animation data

6. **LOD Groups:**
   - Group objects by shared base name
   - Store LOD distances from properties (0x34)
   - Import all LOD levels as separate objects

### For Exporters:

1. **Header:**
   - Write magic "BES\0"
   - Write version (typically "0008")
   - Write exporter ID
   - Generate or skip preview image

2. **Scene Traversal:**
   - Recursive export of object hierarchy
   - Write node chunks (0x01) for each object
   - Maintain parent-child order

3. **Materials:**
   - Collect unique materials
   - Write material list header (0x1000)
   - Export each material (0x1001 or 0x1002)
   - Extract texture paths from shader nodes

4. **Meshes:**
   - Triangulate faces
   - Calculate D3DFVF flags from material
   - Write vertices (0x32) with proper UV ordering
   - Write faces (0x33) as index triplets
   - Write material reference (0x31)

5. **Properties:**
   - Export custom properties as INI format (0x34)
   - Include Lighting, Wobble, Lod parameters
   - Calculate bounding sphere (0x36)

---

## Key Functions in logs.dll

**Main Functions:**
- `BES_Load` (0x1000C6C0) - Main file loader
- `sub_10008DC0` (0x10008DC0) - Chunk parser (recursive)
- `sub_10008B20` (0x10008B20) - Face data parser
- `sub_1008F8D0` (0x1008F8D0) - Mesh parser (chunk 0x51)

**Memory Management:**
- Uses engine's memory allocator
- Materials use malloc for dynamic texture name strings
- Node structures are 160 bytes each

---

## Sample BES Structure

```
BES File (example.bes)
├── Header
│   ├── Magic: "BES\0"
│   ├── Version: "0008"
│   ├── Exporter: 0x1f401100 (3DS Max 8)
│   └── Reserved: 0x00000000
├── Preview (12288 bytes, 64×64 RGB)
└── Data
    ├── Chunk 0x01 (Scene Root)
    │   ├── Name: "Scene Root"
    │   ├── Chunk 0x1000 (Material Count = 2)
    │   ├── Chunk 0x1002 (PteroMat #0)
    │   │   ├── Name: "Wood_Material"
    │   │   ├── Diffuse: "wood.tga"
    │   │   └── Transparency: 0x202D (opaque)
    │   ├── Chunk 0x1002 (PteroMat #1)
    │   │   ├── Name: "Glass_Material"
    │   │   └── Transparency: 0x3123 (1-bit alpha)
    │   ├── Chunk 0x01 (Child Node: "LOD0_Object")
    │   │   ├── Chunk 0x30 (Model)
    │   │   │   ├── Chunk 0x31 (Mesh, Material = 0)
    │   │   │   │   ├── Chunk 0x32 (Vertices: 120)
    │   │   │   │   └── Chunk 0x33 (Faces: 80)
    │   │   │   ├── Chunk 0x34 (Properties: "Lod=15")
    │   │   │   ├── Chunk 0x35 (Transformation)
    │   │   │   └── Chunk 0x36 (BBox: radius=5.2)
    │   ├── Chunk 0x01 (Child Node: "LOD1_Object")
    │   │   └── ... (similar structure, lower detail)
    │   └── ...
    └── Chunk 0x70 (Info)
        ├── Author: "Artist Name"
        ├── Comment: "Exported from 3DS Max"
        └── Total Faces: 320
```

---

## Known Issues & Compatibility

1. **Version Compatibility:**
   - Version 8 is most common and well-supported
   - Version 10 may have extended features
   - Older versions (4-7) have simpler material formats

2. **Transformation Matrix:**
   - May contain calculation errors in exported files
   - Always prefer decomposed translation/rotation/scale

3. **UV Coordinate Ordering:**
   - **CRITICAL:** UV order in vertices differs from flag bit order
   - Must map correctly between Standard/PteroMat and vertex data
   - See detailed flag-to-UV mapping tables above

4. **Texture Paths:**
   - Stored as relative paths
   - May need resolution based on game directory structure
   - Handle .ifl animated textures specially

5. **Material Texture Limits:**
   - Standard materials can have more textures than D3D8 supports (max 8)
   - Engine may skip excessive texture layers

6. **Endianness:**
   - All data is little-endian (x86)
   - Multi-byte values must be read accordingly

---

## Revision History

- **2025-10-11:** Merged specifications from IDA analysis and GitHub documentation
- **2025-01-11:** Initial IDA Pro analysis specification
- **Original:** GitHub community documentation

**Sources:**
- IDA Pro analysis of logs.dll (MD5: 9c0b7596105fa88e81c79263ea961daa)
- Community documentation (GitHub)
- Ptero-Engine-II (2003) reverse engineering

---

*This specification is a living document. Updates will be made as more analysis is completed.*