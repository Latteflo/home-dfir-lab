# MemLabs Lab 3 — Incident Investigation Report

## Case Metadata

| Field | Value |
|---|---|
| Case reference | MEMLABS-LAB3 |
| Analysis date | 2026-03-29 |
| Analyst | Home DFIR Lab |
| Tool | Volatility 3 Framework 2.11.0 |
| Dump file | MemoryDump_Lab3.raw |
| OS identified | Windows 7 SP1 x86 PAE (Build 7601.19135.x86fre.win7sp1_gdr.16) |
| System time at capture | 2018-09-30 09:47:54 UTC |
| Capture tool | DumpIt.exe (PID 4116, user `hello`) |

**Note:** This is the only 32-bit (x86) image in this investigation series.
The previous dumps (Labs 1 and 2) were x86-64. The later patch level
(7601.19135 vs 7601.17514) indicates this image was taken from a more
up-to-date system.

---

## Executive Summary

This Windows 7 SP1 x86 memory dump contains a single interactive user session
for account `hello`. Two Notepad processes were open at capture time: one
viewing a file named `evilscript.py` on the user's Desktop, and a second
viewing `vip.txt` on the same Desktop. The filename `evilscript.py` is the
primary artefact of interest, suggesting the presence of a Python script with
potentially malicious intent or purpose. An `msiexec.exe` process was running
in passive installer mode (`/V`), alongside `TrustedInstaller.exe` and
`wuauclt.exe`, indicating a software installation or Windows Update was in
progress at or shortly before capture. No network connections to external
hosts were present.

---

## Investigation Methodology

| Plugin | Purpose |
|---|---|
| `windows.info` | Confirm OS version and dump integrity |
| `windows.pslist` | Enumerate all processes visible in the EPROCESS list |
| `windows.pstree` | Reconstruct parent-child process relationships |
| `windows.cmdline` | Recover command-line arguments for each process |
| `windows.netscan` | Identify network connections and listening sockets |
| `windows.hashdump` | Extract NTLM credential hashes from the SAM hive |

---

## Findings

### Process Analysis

A single user session (Session ID 1) was active at capture. The user account
is `hello`, as confirmed by the DumpIt.exe path and Notepad file arguments.

**User session — `hello` (Session ID 1)**

| PID | Process | Parent | Notes |
|---|---|---|---|
| 5300 | explorer.exe | 5128 | Desktop shell |
| 3736 | notepad.exe | 5300 (explorer) | Viewing `evilscript.py` on Desktop |
| 3432 | notepad.exe | 5300 (explorer) | Viewing `vip.txt` on Desktop |
| 4116 | DumpIt.exe | 5300 (explorer) | Memory capture tool |
| 3064 | VBoxTray.exe | 5300 (explorer) | VirtualBox guest agent (expected) |

**notepad.exe (PID 3736) — evilscript.py:**
```
"C:\Windows\system32\NOTEPAD.EXE" C:\Users\hello\Desktop\evilscript.py
```
A Python script named `evilscript.py` was open in Notepad on the user's
Desktop. The filename is explicitly adversarial in name. As the content of
the file cannot be recovered from Notepad's process memory through the plugins
used in this investigation, the script's actual function is not determined
here. The file was indexed by the Windows Search service (SearchIndexer.exe,
SearchProtocolHost.exe active), meaning its content may exist in the search
index on disk.

**notepad.exe (PID 3432) — vip.txt:**
```
"C:\Windows\system32\NOTEPAD.EXE" C:\Users\hello\Desktop\vip.txt
```
A second Notepad instance opened `vip.txt` from the same Desktop location.
Both Notepad processes started within one second of each other (3736 at
09:47:49, 3432 at 09:47:50), suggesting they were opened in rapid succession
as part of the same deliberate action — likely reviewing both files together.

**msiexec.exe (PID 1016) and related:**
```
C:\Windows\system32\msiexec.exe /V
```
`msiexec.exe` with the `/V` flag runs the Windows Installer in passive mode
(progress UI but no user prompts). A child `msiexec.exe` (PID 5652) had
already exited by capture time (ExitTime 09:41:17, ~4 minutes before capture).
`TrustedInstaller.exe` (PID 4724, started 09:40:24) and `wuauclt.exe` (PID
5644, started 09:28:49) were also present, indicating Windows Update or a
software installation completed or was in progress during this session.

**System process behaviour:**
All Windows system processes (`svchost.exe`, `lsass.exe`, `services.exe`, etc.)
showed legitimate paths, correct parent relationships, and standard service
parameters. No anomalies in system process space were detected.

---

### Network Connections

No active or recently-closed connections to external hosts were found.
All observed sockets were Windows-internal listeners:

| Owner | Port | Protocol | Notes |
|---|---|---|---|
| System (PID 4) | 139, 445 | TCP LISTEN | SMB |
| svchost.exe (PID 712) | 135 | TCP LISTEN | RPC |
| lsass.exe (PID 492) | 49154 | TCP LISTEN | Authentication |
| svchost.exe (PID 1516) | 3702, 1900 | UDP | WS-Discovery, SSDP |
| VBoxService.exe (PID 648) | ephemeral | UDP | VirtualBox guest comms |

Host IP: `10.0.2.15` — VirtualBox NAT (consistent with VBoxService/VBoxTray).
No external connections, no C2 indicators, no DNS queries captured.

---

### Credential Artefacts

| Username | RID | NT Hash | Notes |
|---|---|---|---|
| Administrator | 500 | `31d6cfe0d16ae931b73c59d7e0c089c0` | Empty password (disabled) |
| Guest | 501 | `31d6cfe0d16ae931b73c59d7e0c089c0` | Empty password (disabled) |
| hello | 1000 | `b963c57010f218edc2cc3c229b5e4d0f` | Only active user account |

Unlike Labs 1 and 2 (which shared the same machine image and user set),
this dump has only one non-system account. The NT hash for `hello` is
distinct from those seen in previous labs.

---

## Indicators of Compromise

| Type | Value | Significance |
|---|---|---|
| File | `C:\Users\hello\Desktop\evilscript.py` | Python script with explicitly adversarial filename, open in Notepad at capture |
| File | `C:\Users\hello\Desktop\vip.txt` | Text file on Desktop open simultaneously with evilscript.py |
| Process | Two `notepad.exe` instances (PID 3736, 3432) | Both opened within 1 second — deliberate simultaneous review |
| Process | `msiexec.exe /V` (PID 1016) + exited child (PID 5652) | Software installation completed ~4 minutes before capture |
| Process | `TrustedInstaller.exe` (PID 4724) | System-level servicing active during session |
| Credential | NT hash `b963c57010f218edc2cc3c229b5e4d0f` (hello) | Single active account; offline cracking applicable |

---

## Conclusions

The defining artefact in this dump is `evilscript.py`, a Python script stored
directly on the Desktop of the `hello` account and open in Notepad at the
moment of memory capture. Its content cannot be determined from the Volatility
plugins applied here; recovering it would require either dumping the Notepad
process's heap memory to extract the loaded file content, or locating the
script via `windows.filescan` and using `windows.dumpfiles`.

The concurrent opening of `evilscript.py` and `vip.txt` in separate Notepad
windows within a one-second window, followed by `DumpIt.exe` running four
minutes later, suggests this session was set up to demonstrate the coexistence
of these files in a live user session.

The software installation activity (`msiexec.exe`, `TrustedInstaller.exe`,
`wuauclt.exe`) is consistent with Windows Update completing prior to the
memory capture. This does not directly relate to the `evilscript.py` artefact
but is notable as environmental context.

No evidence of active malware execution, code injection, or external network
communication was found in this dump.

---

## Appendix — Raw Command Outputs

### A. windows.info

```
Variable        Value
Kernel Base     0x82617000
Is64Bit         False
IsPAE           True
NTBuildLab      7601.19135.x86fre.win7sp1_gdr.16
SystemTime      2018-09-30 09:47:54+00:00
NtSystemRoot    C:\Windows
```

### B. windows.pslist (key processes)

```
PID   PPID  ImageFileName   SessionId  CreateTime
5300  5128  explorer.exe    1          2018-09-30 09:28:36 UTC
3736  5300  notepad.exe     1          2018-09-30 09:47:49 UTC
3432  5300  notepad.exe     1          2018-09-30 09:47:50 UTC
4116  5300  DumpIt.exe      1          2018-09-30 09:45:43 UTC
1016  484   msiexec.exe     0          2018-09-30 09:39:03 UTC
5652  1016  msiexec.exe     1          exited 2018-09-30 09:41:17 UTC
4724  484   TrustedInstall  0          2018-09-30 09:40:24 UTC
```

### C. windows.cmdline (key entries)

```
PID   Process      Args
3736  notepad.exe  "C:\Windows\system32\NOTEPAD.EXE" C:\Users\hello\Desktop\evilscript.py
3432  notepad.exe  "C:\Windows\system32\NOTEPAD.EXE" C:\Users\hello\Desktop\vip.txt
4116  DumpIt.exe   "C:\Users\hello\Desktop\DumpIt\DumpIt.exe"
1016  msiexec.exe  C:\Windows\system32\msiexec.exe /V
```

### D. windows.hashdump

```
User           RID   lmhash                            nthash
Administrator  500   aad3b435b51404eeaad3b435b51404ee  31d6cfe0d16ae931b73c59d7e0c089c0
Guest          501   aad3b435b51404eeaad3b435b51404ee  31d6cfe0d16ae931b73c59d7e0c089c0
hello          1000  aad3b435b51404eeaad3b435b51404ee  b963c57010f218edc2cc3c229b5e4d0f
```
