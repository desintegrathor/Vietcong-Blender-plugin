# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2024 Vietcong Blender Tools Contributors

"""
BES File Reader

High-level reader for BES files that handles header, preview, and chunk parsing.
"""

from typing import Optional
from ..utils.binary_utils import BinaryReader
from .constants import (
    BES_MAGIC,
    HEADER_SIZE,
    PREVIEW_SIZE,
)
from .bes_types import (
    BESFile,
    BESHeader,
    BESPreview,
)


class BESReader:
    """High-level BES file reader."""

    # Versions that don't have preview image
    VERSIONS_WITHOUT_PREVIEW = ('0005', '0004')

    def __init__(self, filepath: str):
        """Initialize reader.

        Args:
            filepath: Path to BES file
        """
        self.filepath = filepath
        self._reader: Optional[BinaryReader] = None
        self._bes_file: Optional[BESFile] = None
        self._has_preview: bool = True
        self._is_skeletal: bool = False

    def __enter__(self):
        self._reader = BinaryReader(self.filepath)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self._reader:
            self._reader.close()
        return False

    def read(self) -> BESFile:
        """Read complete BES file.

        Returns:
            BESFile structure with all data
        """
        if not self._reader:
            raise RuntimeError("Reader not initialized. Use 'with' statement.")

        self._bes_file = BESFile(filepath=self.filepath)

        # Read header
        self._read_header()

        # Read preview image (only for versions that have it)
        if self._has_preview:
            self._read_preview()

        # Store version flags in BESFile for later use
        self._bes_file.is_skeletal = self._is_skeletal

        # Parse chunks
        from .chunk_parser import ChunkParser
        parser = ChunkParser(self._reader, self._bes_file)
        parser.parse()

        return self._bes_file

    def _read_header(self):
        """Read BES file header (16 bytes)."""
        # Read signature
        signature = self._reader.read(4)
        if signature != BES_MAGIC:
            raise ValueError(f"Invalid BES signature: {signature!r}")

        # Read version (4 ASCII chars)
        version = self._reader.read(4).decode('ascii')

        # Read exporter and reserved
        exporter = self._reader.read_uint32()
        reserved = self._reader.read_uint32()

        self._bes_file.header = BESHeader(
            signature=signature,
            version=version,
            exporter=exporter,
            reserved=reserved,
        )

        # Detect version-specific features
        self._has_preview = version not in self.VERSIONS_WITHOUT_PREVIEW
        self._is_skeletal = version in self.VERSIONS_WITHOUT_PREVIEW

    def _read_preview(self):
        """Read preview image (12288 bytes, 64x64 BGR)."""
        pixels = self._reader.read(PREVIEW_SIZE)
        self._bes_file.preview = BESPreview(pixels=pixels)


def read_bes_file(filepath: str) -> BESFile:
    """Convenience function to read a BES file.

    Args:
        filepath: Path to BES file

    Returns:
        BESFile structure with all data
    """
    with BESReader(filepath) as reader:
        return reader.read()
