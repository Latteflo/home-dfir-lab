# Volatility 3 — Command Cheatsheet

All commands assume: `vol.py -f <dump.mem>`

## Process analysis

| Goal | Command |
|---|---|
| List all processes | `windows.pslist` |
| Process tree (parent/child) | `windows.pstree` |
| Detect hidden/unlinked processes | `windows.psscan` |
| Dump a process executable | `windows.procdump --pid <PID>` |
| List DLLs loaded by a process | `windows.dlllist --pid <PID>` |
| List handles for a process | `windows.handles --pid <PID>` |

## Network

| Goal | Command |
|---|---|
| Active and closed connections | `windows.netstat` |
| Network scan (broader) | `windows.netscan` |

## Files and artefacts

| Goal | Command |
|---|---|
| List files cached in memory | `windows.filescan` |
| Dump a specific file | `windows.dumpfiles --virtaddr <addr>` |
| Registry hives in memory | `windows.registry.hivelist` |
| Read a registry key | `windows.registry.printkey --key <path>` |

## Injected code / malware hunting

| Goal | Command |
|---|---|
| Find injected memory sections | `windows.malfind` |
| VAD (Virtual Address Descriptor) tree | `windows.vadinfo --pid <PID>` |
| Dump suspicious memory region | `windows.vadump --pid <PID> --address <addr>` |

## Hashing and verification

```bash
# Hash a dumped file
sha256sum <file>
```

## Useful flags

| Flag | Meaning |
|---|---|
| `-f <file>` | Memory dump path |
| `-o <dir>` | Output directory for dumps |
| `--pid <PID>` | Filter to a specific process |
| `-r <regex>` | Filter output by regex |
