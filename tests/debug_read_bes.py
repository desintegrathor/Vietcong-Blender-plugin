"""Debug BES reading - shows progress."""

import struct

def read_bes_debug(filepath):
    """Read BES with debug output."""
    with open(filepath, 'rb') as f:
        # Header
        sig = f.read(4)
        print(f"Signature: {sig}")

        version = f.read(4).decode('latin-1')
        print(f"Version: {version}")

        if version in ('0100', '0101', '0001', '0008', '0006', '0005'):
            print(f"Valid BES version")
        else:
            print(f"Unknown version!")
            return

        # Skip to first chunk after header/preview
        f.seek(0)
        data = f.read()
        file_size = len(data)
        print(f"File size: {file_size}")

        # Find OBJECT chunk (0x01) - skip preview
        # Preview is typically at offset 0x10 and has size info at 0x10
        f.seek(0x10)
        preview_start = struct.unpack('<I', f.read(4))[0]
        preview_end = struct.unpack('<I', f.read(4))[0]
        print(f"Preview at: 0x{preview_start:X} - 0x{preview_end:X}")

        # Jump to first chunk after preview
        pos = preview_end
        f.seek(pos)

        chunk_count = 0
        max_chunks = 100  # Safety limit

        while pos < file_size and chunk_count < max_chunks:
            if file_size - pos < 8:
                print(f"Remaining bytes: {file_size - pos}, not enough for header")
                break

            chunk_type = struct.unpack('<I', f.read(4))[0]
            total_size = struct.unpack('<I', f.read(4))[0]
            data_size = total_size - 8

            print(f"[0x{pos:08X}] Chunk 0x{chunk_type:04X}, size={total_size} (data={data_size})")

            if data_size < 0:
                print(f"  ERROR: Negative data size!")
                break

            if data_size > 0:
                # For OBJECT/ISKE, show name
                if chunk_type in (0x01, 0x50):
                    child_count = struct.unpack('<I', f.read(4))[0]
                    name_len = struct.unpack('<I', f.read(4))[0]
                    name = f.read(name_len).decode('latin-1')
                    print(f"  Name: {name}, children={child_count}")
                    # Don't skip this chunk's content - it contains nested chunks
                    # Reset position to after name
                    f.seek(pos + 8 + 8 + name_len)
                    pos = f.tell()
                else:
                    # Skip chunk data
                    f.seek(pos + total_size)
                    pos = f.tell()
            else:
                pos = f.tell()

            chunk_count += 1

        print(f"\nParsed {chunk_count} chunks")

if __name__ == "__main__":
    import sys
    filepath = sys.argv[1] if len(sys.argv) > 1 else 'tests/CUP_BANGS.BES'
    read_bes_debug(filepath)
