# Volatility 3 — Setup

## Installation (NixOS / nix-shell)

Volatility 3 is run via a `nix-shell` environment with Python 3 and the
required dependencies. No system-wide installation needed.

```bash
nix-shell -p python3 python3Packages.pip python3Packages.setuptools
pip install volatility3
```

Or via a dedicated `shell.nix` (see repo root if present).

Verify:

```bash
vol.py --help
```

## Running against a memory dump

```bash
vol.py -f <dump.mem> <plugin>
```

All case-specific commands are documented in each case report under
`cases/`.

## Symbol tables

Volatility 3 uses ISF (Intermediate Symbol Format) symbol tables instead of
profiles (Volatility 2). For Linux analysis, you may need to build a custom
symbol table matching the kernel version of the source machine.

For Windows memory dumps (MemLabs), symbol tables are fetched automatically
from Microsoft's public symbol server on first use. Requires internet access
during initial run.

## References

- Volatility 3 docs: https://volatility3.readthedocs.io
- MemLabs: https://github.com/stuxnet999/MemLabs
