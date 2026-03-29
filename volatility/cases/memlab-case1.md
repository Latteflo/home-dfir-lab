# MemLabs Lab 1 — Incident Investigation Report

## Case Metadata

| Field | Value |
|---|---|
| Case reference | MEMLABS-LAB1 |
| Analysis date | 2026-03-29 |
| Analyst | Home DFIR Lab |
| Tool | Volatility 3 Framework 2.11.0 |
| Dump file | MemoryDump_Lab1.raw |
| OS identified | Windows 7 SP1 x64 (Build 7601.17514.amd64fre.win7sp1_rtm) |
| System time at capture | 2019-12-11 14:38:00 UTC |
| Capture tool | DumpIt.exe (PID 796, run by user SmartNet) |

---

## Executive Summary

Analysis of this Windows 7 SP1 memory dump reveals two active user sessions at
the time of capture: `SmartNet` (Session 1) and `Alissa Simpson` (Session 2).
The `SmartNet` account launched a command prompt (`cmd.exe`) and the memory
capture tool (`DumpIt.exe`), while `Alissa Simpson`'s session shows `WinRAR.exe`
actively opening a file named `Important.rar` from her Documents folder.
The presence of an archive operation on a file with a sensitive-sounding name,
combined with two concurrent sessions and extracted credential hashes for all
five local accounts, constitutes the primary area of forensic interest.

---

## Investigation Methodology

The following Volatility 3 plugins were executed against the dump in sequence:

| Plugin | Purpose |
|---|---|
| `windows.info` | Confirm OS version and dump integrity |
| `windows.pslist` | Enumerate all processes visible in the EPROCESS list |
| `windows.pstree` | Reconstruct parent-child process relationships |
| `windows.cmdline` | Recover command-line arguments for each process |
| `windows.netscan` | Identify network connections and listening sockets |
| `windows.filescan` | Enumerate file objects cached in memory |
| `windows.hashdump` | Extract NTLM credential hashes from the SAM hive |

The `--symbol-dirs ~/.cache/volatility3/symbols` flag was used on all commands
to route Windows symbol downloads to a writable path (required on NixOS where
the Volatility package directory is in the read-only Nix store).

---

## Findings

### Process Analysis

At the time of capture there were **two active user sessions** running
concurrently: Session 1 (user `SmartNet`) and Session 2 (user `Alissa Simpson`).
Each session had its own `explorer.exe`, `csrss.exe`, `winlogon.exe`, `dwm.exe`,
and `taskhost.exe` — consistent with Windows Fast User Switching.

**Session 1 — SmartNet (Session ID 1)**

| PID | Process | Parent | Notes |
|---|---|---|---|
| 604 | explorer.exe | 2016 | Desktop shell for SmartNet |
| 1984 | cmd.exe | 604 (explorer) | Command prompt opened manually |
| 2424 | mspaint.exe | 604 (explorer) | Paint application, no file argument |
| 796 | DumpIt.exe | 604 (explorer) | Memory capture tool; created this dump |
| 1844 | VBoxTray.exe | 604 (explorer) | VirtualBox guest agent (expected) |

`cmd.exe` (PID 1984) was launched directly from explorer with no additional
arguments. A `conhost.exe` (PID 2692) was spawned as its console host,
confirming the terminal was active.

`DumpIt.exe` (PID 796) runs as a 32-bit process (Wow64=True) from
`C:\Users\SmartNet\Downloads\DumpIt\DumpIt.exe`. This is the tool responsible
for capturing the memory image being analysed.

`mspaint.exe` (PID 2424) was running with no file argument, suggesting an image
may have been opened interactively via the File menu rather than by
double-clicking, or was created within the session.

**Session 2 — Alissa Simpson (Session ID 2)**

| PID | Process | Parent | Notes |
|---|---|---|---|
| 2504 | explorer.exe | 3000 | Desktop shell for Alissa Simpson |
| 1512 | WinRAR.exe | 2504 (explorer) | Opening Important.rar from Documents |
| 2304 | VBoxTray.exe | 2504 (explorer) | VirtualBox guest agent (expected) |

`WinRAR.exe` (PID 1512) was launched with the explicit argument:
```
"C:\Program Files\WinRAR\WinRAR.exe" "C:\Users\Alissa Simpson\Documents\Important.rar"
```
This indicates the archive was opened directly, either by double-clicking or
via a shortcut. The archive name `Important.rar` and its location in the user's
Documents folder are noteworthy.

**System-level processes** (Sessions 0): All standard Windows services
(`svchost.exe` instances, `spoolsv.exe`, `lsass.exe`, `services.exe`,
`SearchIndexer.exe`) were present with expected parent-child relationships
and legitimate command-line arguments. No anomalies detected in system
process space.

---

### Network Connections

No active outbound TCP connections to external addresses were present at the
time of capture. The network activity observed was entirely Windows-internal:

| Owner | Port(s) | Protocol | Assessment |
|---|---|---|---|
| `TCPSVCS.EXE` (PID 1416) | 7, 9, 13, 17, 19 | TCP/UDP | Legacy echo/discard/chargen services; unusual but part of Windows Simple TCP/IP Services feature |
| `lsass.exe` (PID 492) | 49154 | TCP LISTEN | Standard Windows authentication port |
| `svchost.exe` (PID 472) | 3702, 59435–59438 | UDP | WS-Discovery (normal) |
| `wmpnetwk.exe` (PID 1856) | 554, 5004, 5005 | TCP/UDP | Windows Media Player network sharing |
| `System` (PID 4) | 139, 445 | TCP LISTEN | SMB; expected on a Windows host |

The host IP was `10.0.2.15` — a VirtualBox NAT default address, consistent
with the `VBoxService.exe` / `VBoxTray.exe` processes and the lab environment.

No evidence of active C2 communication, lateral movement, or data exfiltration
via network was present in memory at capture time.

---

### Command History

`cmd.exe` (PID 1984) was running under SmartNet's session with no arguments
beyond the executable path itself (`"C:\Windows\system32\cmd.exe"`). No
additional command history is recoverable from the process list alone; console
history would require a `windows.cmdline` or `windows.consoles` deep-dive on
the `conhost.exe` handle space, which was not performed in this investigation.

---

### Credential Artefacts

`windows.hashdump` recovered NTLM hashes for all five local accounts:

| Username | RID | NT Hash | Notes |
|---|---|---|---|
| Administrator | 500 | `31d6cfe0d16ae931b73c59d7e0c089c0` | Empty password hash (disabled account) |
| Guest | 501 | `31d6cfe0d16ae931b73c59d7e0c089c0` | Empty password hash (disabled account) |
| SmartNet | 1001 | `4943abb39473a6f32c11301f4987e7e0` | Active user account |
| HomeGroupUser$ | 1002 | `f0fc3d257814e08fea06e63c5762ebd5` | HomeGroup service account |
| Alissa Simpson | 1003 | `f4ff64c8baac57d22f22edc681055ba6` | Active user account |

The LM hashes for all accounts are the standard empty-LM placeholder
(`aad3b435b51404eeaad3b435b51404ee`), meaning LM authentication is disabled
system-wide — expected on Windows 7.

The NT hashes for `SmartNet` and `Alissa Simpson` are non-empty and could
be subjected to offline cracking (e.g. against a dictionary or rainbow table)
to recover plaintext passwords. This is noted as a forensic capability, not
an action taken in this investigation.

---

### Files of Interest

`windows.filescan` filtered for document, archive, image, and executable types
surfaced the following items of interest:

| Path | Significance |
|---|---|
| `C:\Users\Alissa Simpson\Documents\Important.rar` | Actively open in WinRAR (PID 1512) at time of capture |
| `C:\Users\SmartNet\Downloads\DumpIt\DumpIt.exe` | Memory capture tool used to produce this dump |
| `C:\Users\SmartNet\NTUSER.DAT` | Registry hive for SmartNet; in-memory at capture |
| `C:\Users\Alissa Simpson\NTUSER.DAT` | Registry hive for Alissa Simpson; in-memory at capture |

The file `Important.rar` could not be extracted directly from this
investigation's scope but its presence in memory (as an open file handle
within WinRAR's process) confirms it existed on the filesystem at capture time.

---

## Indicators of Compromise

| Type | Value | Significance |
|---|---|---|
| Process | `DumpIt.exe` (PID 796) at `C:\Users\SmartNet\Downloads\DumpIt\DumpIt.exe` | Deliberate memory acquisition by SmartNet user |
| Process | `cmd.exe` (PID 1984) spawned from `explorer.exe` | Interactive command prompt opened by SmartNet |
| Process | `WinRAR.exe` (PID 1512) with argument `Important.rar` | Archive operation on a file in Alissa Simpson's Documents |
| Credential | NT hash `4943abb39473a6f32c11301f4987e7e0` (SmartNet) | Recoverable via offline attack |
| Credential | NT hash `f4ff64c8baac57d22f22edc681055ba6` (Alissa Simpson) | Recoverable via offline attack |
| File | `C:\Users\Alissa Simpson\Documents\Important.rar` | Archive present in second user's Documents folder |
| Network | `TCPSVCS.EXE` listening on ports 7, 9, 13, 17, 19 | Legacy network services enabled; uncommon in modern environments |

---

## Conclusions

This memory image captures a Windows 7 SP1 VirtualBox guest with two
concurrently active user sessions. The primary user `SmartNet` opened a
command prompt and subsequently ran `DumpIt.exe` to produce this memory image.
The secondary user `Alissa Simpson` had `WinRAR.exe` open against a file named
`Important.rar` in her Documents directory at the time of capture.

The most forensically significant observation is the combination of:
1. An active archive operation (`WinRAR.exe` on `Important.rar`) in a second
   user session, suggesting either data packaging or access to stored archives.
2. An open command prompt in the primary session, indicating interactive use
   shortly before the dump was taken.
3. Recoverable NTLM hashes for all active accounts.

No evidence of malware, code injection, rootkit activity, or external network
connections was found in this dump. The activity is consistent with a
deliberate forensic exercise rather than an active intrusion scenario.

---

## Appendix — Raw Command Outputs

### A. windows.info

```
Variable        Value
Kernel Base     0xf8000261f000
NTBuildLab      7601.17514.amd64fre.win7sp1_rtm.
SystemTime      2019-12-11 14:38:00+00:00
NtSystemRoot    C:\Windows
```

### B. windows.pslist (abbreviated — key processes)

```
PID   PPID  ImageFileName   SessionId  Wow64  CreateTime
604   2016  explorer.exe    1          False  2019-12-11 14:32:25 UTC
1984  604   cmd.exe         1          False  2019-12-11 14:34:54 UTC
2424  604   mspaint.exe     1          False  2019-12-11 14:35:14 UTC
796   604   DumpIt.exe      1          True   2019-12-11 14:37:54 UTC
2504  3000  explorer.exe    2          False  2019-12-11 14:37:14 UTC
1512  2504  WinRAR.exe      2          False  2019-12-11 14:37:23 UTC
```

### C. windows.cmdline (key entries)

```
PID   Process      Args
1984  cmd.exe      "C:\Windows\system32\cmd.exe"
2424  mspaint.exe  "C:\Windows\system32\mspaint.exe"
796   DumpIt.exe   "C:\Users\SmartNet\Downloads\DumpIt\DumpIt.exe"
1512  WinRAR.exe   "C:\Program Files\WinRAR\WinRAR.exe" "C:\Users\Alissa Simpson\Documents\Important.rar"
```

### D. windows.hashdump

```
User              RID   lmhash                            nthash
Administrator     500   aad3b435b51404eeaad3b435b51404ee  31d6cfe0d16ae931b73c59d7e0c089c0
Guest             501   aad3b435b51404eeaad3b435b51404ee  31d6cfe0d16ae931b73c59d7e0c089c0
SmartNet          1001  aad3b435b51404eeaad3b435b51404ee  4943abb39473a6f32c11301f4987e7e0
HomeGroupUser$    1002  aad3b435b51404eeaad3b435b51404ee  f0fc3d257814e08fea06e63c5762ebd5
Alissa Simpson    1003  aad3b435b51404eeaad3b435b51404ee  f4ff64c8baac57d22f22edc681055ba6
```

### E. windows.netscan (notable entries)

```
Proto   LocalAddr    LocalPort  ForeignAddr  State      PID   Owner
TCPv4   10.0.2.15    139        0.0.0.0      LISTENING  4     System
TCPv4   0.0.0.0      445        0.0.0.0      LISTENING  4     System
TCPv4   0.0.0.0      19         0.0.0.0      LISTENING  1416  TCPSVCS.EXE
TCPv4   0.0.0.0      17         0.0.0.0      LISTENING  1416  TCPSVCS.EXE
TCPv4   0.0.0.0      13         0.0.0.0      LISTENING  1416  TCPSVCS.EXE
TCPv4   0.0.0.0      9          0.0.0.0      LISTENING  1416  TCPSVCS.EXE
TCPv4   0.0.0.0      7          0.0.0.0      LISTENING  1416  TCPSVCS.EXE
```
