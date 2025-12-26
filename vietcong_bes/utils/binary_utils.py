# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
Binary I/O Utilities

Helper classes for reading and writing binary data in little-endian format
as used by the BES file format.
"""

import struct
from typing import Tuple, List, BinaryIO, Optional
from io import BytesIO


class BinaryReader:
    """Binary file reader with little-endian support."""

    def __init__(self, source):
        """Initialize reader.

        Args:
            source: File path (str), file object, or bytes
        """
        if isinstance(source, str):
            self._file = open(source, 'rb')
            self._owns_file = True
        elif isinstance(source, bytes):
            self._file = BytesIO(source)
            self._owns_file = True
        else:
            self._file = source
            self._owns_file = False

        self._file.seek(0, 2)  # Seek to end
        self._size = self._file.tell()
        self._file.seek(0)  # Seek back to start

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
        return False

    def close(self):
        """Close the file if we own it."""
        if self._owns_file and self._file:
            self._file.close()

    @property
    def size(self) -> int:
        """Get total file size."""
        return self._size

    @property
    def position(self) -> int:
        """Get current read position."""
        return self._file.tell()

    @property
    def remaining(self) -> int:
        """Get remaining bytes to read."""
        return self._size - self._file.tell()

    def seek(self, offset: int, whence: int = 0):
        """Seek to position.

        Args:
            offset: Byte offset
            whence: 0=start, 1=current, 2=end
        """
        self._file.seek(offset, whence)

    def skip(self, count: int):
        """Skip bytes."""
        self._file.seek(count, 1)

    def read(self, count: int) -> bytes:
        """Read raw bytes."""
        return self._file.read(count)

    def read_all(self) -> bytes:
        """Read all remaining bytes."""
        return self._file.read()

    # Integer readers (little-endian)

    def read_uint8(self) -> int:
        """Read unsigned 8-bit integer."""
        return struct.unpack('<B', self._file.read(1))[0]

    def read_int8(self) -> int:
        """Read signed 8-bit integer."""
        return struct.unpack('<b', self._file.read(1))[0]

    def read_uint16(self) -> int:
        """Read unsigned 16-bit integer."""
        return struct.unpack('<H', self._file.read(2))[0]

    def read_int16(self) -> int:
        """Read signed 16-bit integer."""
        return struct.unpack('<h', self._file.read(2))[0]

    def read_uint32(self) -> int:
        """Read unsigned 32-bit integer."""
        return struct.unpack('<I', self._file.read(4))[0]

    def read_int32(self) -> int:
        """Read signed 32-bit integer."""
        return struct.unpack('<i', self._file.read(4))[0]

    def read_uint64(self) -> int:
        """Read unsigned 64-bit integer."""
        return struct.unpack('<Q', self._file.read(8))[0]

    def read_int64(self) -> int:
        """Read signed 64-bit integer."""
        return struct.unpack('<q', self._file.read(8))[0]

    # Float readers (little-endian)

    def read_float(self) -> float:
        """Read 32-bit float."""
        return struct.unpack('<f', self._file.read(4))[0]

    def read_double(self) -> float:
        """Read 64-bit double."""
        return struct.unpack('<d', self._file.read(8))[0]

    # Vector readers

    def read_vec2(self) -> Tuple[float, float]:
        """Read 2D vector (2 floats)."""
        return struct.unpack('<2f', self._file.read(8))

    def read_vec3(self) -> Tuple[float, float, float]:
        """Read 3D vector (3 floats)."""
        return struct.unpack('<3f', self._file.read(12))

    def read_vec4(self) -> Tuple[float, float, float, float]:
        """Read 4D vector (4 floats)."""
        return struct.unpack('<4f', self._file.read(16))

    def read_matrix4x4(self) -> List[List[float]]:
        """Read 4x4 matrix (16 floats, row-major)."""
        values = struct.unpack('<16f', self._file.read(64))
        return [
            list(values[0:4]),
            list(values[4:8]),
            list(values[8:12]),
            list(values[12:16]),
        ]

    # String readers

    def read_string(self, length: int) -> str:
        """Read fixed-length string.

        Args:
            length: Number of bytes to read (including NULL terminator)

        Returns:
            String without NULL terminator
        """
        data = self._file.read(length)
        # Find NULL terminator
        null_pos = data.find(b'\x00')
        if null_pos >= 0:
            data = data[:null_pos]
        return data.decode('latin-1')

    def read_cstring(self) -> str:
        """Read NULL-terminated string."""
        chars = []
        while True:
            c = self._file.read(1)
            if not c or c == b'\x00':
                break
            chars.append(c)
        return b''.join(chars).decode('latin-1')

    def read_string_with_length(self) -> str:
        """Read string prefixed with uint32 length."""
        length = self.read_uint32()
        return self.read_string(length)

    # BES-specific readers

    def read_chunk_header(self) -> Tuple[int, int]:
        """Read BES chunk header (type, size).

        Note: BES chunk size INCLUDES the 8-byte header itself.
        This function returns the DATA size (excluding header).

        Returns:
            Tuple of (chunk_type, data_size)
        """
        chunk_type = self.read_uint32()
        total_size = self.read_uint32()
        # Size in file includes the 8-byte header, return just the data size
        data_size = total_size - 8
        return chunk_type, data_size

    def unpack(self, fmt: str, size: int) -> tuple:
        """Unpack data with struct format.

        Args:
            fmt: Struct format string (should include '<' for little-endian)
            size: Number of bytes to read

        Returns:
            Unpacked tuple
        """
        return struct.unpack(fmt, self._file.read(size))


class BinaryWriter:
    """Binary file writer with little-endian support."""

    def __init__(self, target=None):
        """Initialize writer.

        Args:
            target: File path (str), file object, or None for BytesIO
        """
        if target is None:
            self._file = BytesIO()
            self._owns_file = True
        elif isinstance(target, str):
            self._file = open(target, 'wb')
            self._owns_file = True
        else:
            self._file = target
            self._owns_file = False

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
        return False

    def close(self):
        """Close the file if we own it."""
        if self._owns_file and self._file:
            self._file.close()

    def get_bytes(self) -> bytes:
        """Get written bytes (only for BytesIO)."""
        if isinstance(self._file, BytesIO):
            return self._file.getvalue()
        raise ValueError("Cannot get bytes from file writer")

    @property
    def position(self) -> int:
        """Get current write position."""
        return self._file.tell()

    def seek(self, offset: int, whence: int = 0):
        """Seek to position."""
        self._file.seek(offset, whence)

    def write(self, data: bytes):
        """Write raw bytes."""
        self._file.write(data)

    # Integer writers (little-endian)

    def write_uint8(self, value: int):
        """Write unsigned 8-bit integer."""
        self._file.write(struct.pack('<B', value))

    def write_int8(self, value: int):
        """Write signed 8-bit integer."""
        self._file.write(struct.pack('<b', value))

    def write_uint16(self, value: int):
        """Write unsigned 16-bit integer."""
        self._file.write(struct.pack('<H', value))

    def write_int16(self, value: int):
        """Write signed 16-bit integer."""
        self._file.write(struct.pack('<h', value))

    def write_uint32(self, value: int):
        """Write unsigned 32-bit integer."""
        self._file.write(struct.pack('<I', value))

    def write_int32(self, value: int):
        """Write signed 32-bit integer."""
        self._file.write(struct.pack('<i', value))

    def write_uint64(self, value: int):
        """Write unsigned 64-bit integer."""
        self._file.write(struct.pack('<Q', value))

    def write_int64(self, value: int):
        """Write signed 64-bit integer."""
        self._file.write(struct.pack('<q', value))

    # Float writers (little-endian)

    def write_float(self, value: float):
        """Write 32-bit float."""
        self._file.write(struct.pack('<f', value))

    def write_double(self, value: float):
        """Write 64-bit double."""
        self._file.write(struct.pack('<d', value))

    # Vector writers

    def write_vec2(self, value: Tuple[float, float]):
        """Write 2D vector (2 floats)."""
        self._file.write(struct.pack('<2f', *value))

    def write_vec3(self, value: Tuple[float, float, float]):
        """Write 3D vector (3 floats)."""
        self._file.write(struct.pack('<3f', *value))

    def write_vec4(self, value: Tuple[float, float, float, float]):
        """Write 4D vector (4 floats)."""
        self._file.write(struct.pack('<4f', *value))

    def write_matrix4x4(self, matrix: List[List[float]]):
        """Write 4x4 matrix (16 floats, row-major)."""
        values = []
        for row in matrix:
            values.extend(row)
        self._file.write(struct.pack('<16f', *values))

    # String writers

    def write_string(self, value: str, length: int):
        """Write fixed-length string with NULL padding.

        Args:
            value: String to write
            length: Total length including NULL terminator
        """
        data = value.encode('latin-1')[:length - 1]
        data = data + b'\x00' * (length - len(data))
        self._file.write(data)

    def write_cstring(self, value: str):
        """Write NULL-terminated string."""
        self._file.write(value.encode('latin-1') + b'\x00')

    def write_string_with_length(self, value: str):
        """Write string prefixed with uint32 length (including NULL)."""
        data = value.encode('latin-1') + b'\x00'
        self.write_uint32(len(data))
        self._file.write(data)

    # BES-specific writers

    def write_chunk_header(self, chunk_type: int, data_size: int):
        """Write BES chunk header."""
        self.write_uint32(chunk_type)
        self.write_uint32(data_size)

    def write_zeros(self, count: int):
        """Write zero bytes."""
        self._file.write(b'\x00' * count)

    def pack(self, fmt: str, *values):
        """Pack and write data with struct format.

        Args:
            fmt: Struct format string (should include '<' for little-endian)
            *values: Values to pack
        """
        self._file.write(struct.pack(fmt, *values))


class ChunkBuilder:
    """Helper for building BES chunks with automatic size calculation."""

    def __init__(self, chunk_type: int):
        """Initialize chunk builder.

        Args:
            chunk_type: Chunk type ID
        """
        self.chunk_type = chunk_type
        self._writer = BinaryWriter()

    @property
    def writer(self) -> BinaryWriter:
        """Get the internal writer for adding data."""
        return self._writer

    def build(self) -> bytes:
        """Build complete chunk with header.

        Returns:
            Complete chunk bytes (header + data)
        """
        data = self._writer.get_bytes()
        result = BinaryWriter()
        # BES chunk size includes the 8-byte header itself
        result.write_chunk_header(self.chunk_type, len(data) + 8)
        result.write(data)
        return result.get_bytes()

    @property
    def data_size(self) -> int:
        """Get current data size."""
        return self._writer.position
