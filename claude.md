# Project info

We are creating a Blender plugin for Vietcong game. Reverse engineering the game engine and an old 3DS Max Plugin in IDA Pro.
If you need to open a specific binary in ida pro - stop and ask the user to load it.


# IDA Pro MCP

Use the ida-pro-mcp tools for all reverse engineering tasks.

## Tool names (exact):
- ida-pro-mcp:idb_meta
- ida-pro-mcp:list_funcs
- ida-pro-mcp:lookup_funcs
- ida-pro-mcp:decompile
- ida-pro-mcp:disasm
- ida-pro-mcp:xrefs_to
- ida-pro-mcp:callers
- ida-pro-mcp:callees
- ida-pro-mcp:strings
- ida-pro-mcp:analyze_funcs
- ida-pro-mcp:rename
- ida-pro-mcp:search
- ida-pro-mcp:imports
- ida-pro-mcp:segments
- ida-pro-mcp:basic_blocks

## Parameter formats:
- Addresses: use hex strings like "0x10001234"
- For decompile/disasm: `{"addrs": "0x10001234"}`
- For list_funcs: `{"queries": {"filter": "*name*", "count": 50}}`
- For rename functions: `{"batch": {"func": [{"addr": "0x10001234", "name": "new_name"}]}}`

## Always:
1. Call idb_meta first to verify connection
2. Use exact tool names with "ida-pro-mcp:" prefix
3. Pass addresses as hex strings, not integers


