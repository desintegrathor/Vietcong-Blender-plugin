# BES Test Files

Place your BES test files in this folder for testing the import/export functionality.

## Expected test files

- `*.bes` - BES model files from Vietcong/Vietcong 2
- Textures (DDS/TGA/BMP) can be placed alongside BES files

## Testing procedure

1. Install the plugin in Blender 4.x
2. File > Import > Vietcong BES (.bes)
3. Select a test file from this folder
4. Verify geometry, materials, and hierarchy are correct
5. Try re-exporting (File > Export > Vietcong BES)
6. Re-import the exported file to verify round-trip consistency

## Known test files to request

- Simple model with single material
- Complex model with multiple materials
- Model with PteroMat transparency
- Model with LOD levels
- Model with Wobble animation
- Hierarchical scene with multiple objects
