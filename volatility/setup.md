# Volatility 3 — Setup

## 1. Enter the nix-shell environment

From the repo root:

```bash
nix-shell
```

This drops you into a shell with Python 3, pip, setuptools, git, and wget
available. The `shellHook` sets `~/.local/bin` on your PATH so that
pip-installed tools like `vol` are immediately accessible.

## 2. Install Volatility 3

Inside the nix-shell:

```bash
pip install volatility3 --user
```

This installs Volatility 3 and its dependencies under `~/.local/`. The
`--user` flag keeps it out of the Nix store and avoids permission issues.

Verify the install:

```bash
vol -h
```

You should see the Volatility 3 help output listing available plugins.

## 3. Obtain the memory dump (manual step)

MemLabs Lab 1 is hosted on MEGA, which requires a browser-based download
due to client-side decryption — `wget` and `curl` cannot retrieve MEGA links
directly.

**Manual step:**

1. Open the MEGA link in a browser:
   `https://mega.nz/file/6l4BhKIb#l8ATZoliB_a5dAHs4PqhRFt7wnkOBLAWtKD97Rl8lQ4`
2. Download the file (it will be a `.zip` or `.raw`).
3. Extract if needed and place the raw dump at:
   `volatility/cases/dumps/MemLabs-Lab1.raw`

Create the target directory first:

```bash
mkdir -p volatility/cases/dumps
```

The `dumps/` directory is listed in `.gitignore` — memory dumps are large
binary files and are not committed to the repo.

## 4. Run your first command

From the repo root, inside nix-shell:

```bash
vol -f volatility/cases/dumps/MemLabs-Lab1.raw windows.info
```

This confirms Volatility can read the dump and identifies the Windows version.

## Notes

- Volatility 3 fetches Windows symbol tables from Microsoft's public symbol
  server on first use. This requires internet access and may take a minute.
  Symbols are cached in `~/.cache/volatility3/` after the first run.
- All case-specific commands and findings are documented in
  `volatility/cases/memlab-case1.md`.
