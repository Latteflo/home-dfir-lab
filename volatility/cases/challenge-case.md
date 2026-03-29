# Challenge — Incident Investigation Report

## Case Metadata

| Field | Value |
|---|---|
| Case reference | CHALLENGE-001 |
| Analysis date | 2026-03-29 |
| Analyst | Home DFIR Lab |
| Tool | Volatility 3 Framework 2.11.0 |
| Dump file | Challenge.raw |
| OS identified | Windows 7 SP1 x86 PAE (Build 7601.24260.x86fre.win7sp1_ldr.18) |
| System time at capture | 2018-10-23 08:30:51 UTC |
| Capture tool | DumpIt.exe (PID 2412, user `hello`) |

**Note:** This image shares the same OS architecture as MemLabs Lab 3
(Windows 7 SP1 x86 PAE, user `hello`), but is a distinct capture from a
different point in time (Lab 3: 2018-09-30; Challenge: 2018-10-23) and carries
a different NT hash for the `hello` account, confirming the password was
changed between captures.

---

## Executive Summary

This Windows 7 SP1 x86 memory dump captures a single user session (`hello`)
with a command prompt (`cmd.exe`) open and active. The command prompt was
launched 30 seconds before `DumpIt.exe` ran, and a dedicated `conhost.exe`
instance was present to host it, confirming the terminal was in use at or
immediately before capture. No other user-initiated applications (browsers,
document viewers, archive tools) were running. The process list is minimal and
clean: no evidence of malware, code injection, or suspicious processes was
found. No external network connections were observed. The primary forensic
interest is the active command prompt and any commands that may have been
executed within it — content not recoverable through the plugins used in this
investigation.

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
is `hello`, confirmed by the DumpIt.exe path.

**User session — `hello` (Session ID 1)**

| PID | Process | Parent | Notes |
|---|---|---|---|
| 324 | explorer.exe | 1876 | Desktop shell |
| 2096 | cmd.exe | 324 (explorer) | Active command prompt |
| 2104 | conhost.exe | 380 (csrss) | Console host for cmd.exe |
| 2412 | DumpIt.exe | 324 (explorer) | Memory capture tool |
| 2424 | conhost.exe | 380 (csrss) | Console host for DumpIt.exe |
| 1000 | VBoxTray.exe | 324 (explorer) | VirtualBox guest agent (expected) |

**cmd.exe (PID 2096):**
```
"C:\Windows\system32\cmd.exe"
```
Launched from `explorer.exe` at 08:30:18, 30 seconds before DumpIt ran at
08:30:48. A `conhost.exe` (PID 2104) was spawned as its console host,
confirming the terminal was live. The command line contains no arguments,
meaning the shell was opened interactively (double-click, Run dialog, or
keyboard shortcut). The contents of any commands typed within the session are
not recoverable through `windows.cmdline` alone; `windows.consoles` would be
required to extract the console input/output buffer.

**Process timeline (Session 1 user activity):**

| Time (UTC) | Event |
|---|---|
| 08:30:04 | explorer.exe started (user logged in) |
| 08:30:08 | VBoxTray.exe started |
| 08:30:14 | SearchIndexer.exe started (indexing begins) |
| 08:30:18 | cmd.exe launched + conhost.exe spawned |
| 08:30:48 | DumpIt.exe launched + second conhost.exe spawned |
| 08:30:51 | Memory captured |

The session was approximately 47 seconds old at capture time. The user logged
in, opened a command prompt within 14 seconds, and triggered the memory dump
30 seconds later.

**System processes:**
All Windows system processes showed legitimate paths, expected parent-child
relationships, and standard service parameters. No anomalies detected.

Compared to Lab 3 (same OS / user), this image is notably absent of:
- Notepad instances viewing files
- msiexec / TrustedInstaller / Windows Update activity
- Any document, script, or archive files referenced in process arguments

The session is simpler and more focused on the command-line environment.

---

### Network Connections

No active or recently-closed connections to external hosts were found.
All sockets were Windows-internal listeners:

| Owner | Port | Protocol | Notes |
|---|---|---|---|
| System (PID 4) | 139, 445 | TCP LISTEN | SMB |
| svchost.exe (PID 716) | 135 | TCP LISTEN | RPC |
| lsass.exe (PID 492) | 49154 | TCP LISTEN | Authentication |
| svchost.exe (PID 1488) | 3702 | UDP | WS-Discovery |
| VBoxService.exe (PID 652) | ephemeral | UDP | VirtualBox guest comms |

Host IP: `10.0.2.15` — VirtualBox NAT. No outbound connections, no DNS queries
captured. The network surface at capture time was fully passive.

---

### Credential Artefacts

| Username | RID | NT Hash | Notes |
|---|---|---|---|
| Administrator | 500 | `31d6cfe0d16ae931b73c59d7e0c089c0` | Empty password (disabled) |
| Guest | 501 | `31d6cfe0d16ae931b73c59d7e0c089c0` | Empty password (disabled) |
| hello | 1000 | `101da33f44e92c27835e64322d72e8b7` | Active user; different hash from Lab 3 |

The NT hash for `hello` (`101da33f44e92c27835e64322d72e8b7`) differs from the
Lab 3 hash (`b963c57010f218edc2cc3c229b5e4d0f`), confirming a password change
between the two captures (2018-09-30 → 2018-10-23).

---

## Indicators of Compromise

| Type | Value | Significance |
|---|---|---|
| Process | `cmd.exe` (PID 2096) launched 30s before DumpIt | Active command prompt immediately before memory capture |
| Credential | NT hash `101da33f44e92c27835e64322d72e8b7` (hello) | Changed from Lab 3 value; offline cracking applicable |
| Timing | Session age ~47 seconds at capture | Very short session; user logged in specifically to run DumpIt |

No additional IOCs were identified. The process set is minimal and all
observed processes are either standard Windows components or expected VirtualBox
artefacts.

---

## Conclusions

This image represents the simplest of the four captures in this investigation
series. The user `hello` logged into a Windows 7 SP1 x86 VM, opened a command
prompt within 14 seconds, and triggered a memory dump 30 seconds later. The
brevity and focus of the session suggests this was a purpose-built forensic
capture rather than a snapshot of active system use.

The key limitation of this analysis is that the contents of the `cmd.exe`
session are not recoverable through the plugins applied here. To determine what
commands were run, the `windows.consoles` plugin or a manual heap dump of the
`conhost.exe` process would be required as a follow-on step.

No evidence of malware, network compromise, credential theft, or code injection
was found in this dump.

---

## Appendix — Raw Command Outputs

### A. windows.info

```
Variable        Value
Kernel Base     0x82604000
Is64Bit         False
IsPAE           True
NTBuildLab      7601.24260.x86fre.win7sp1_ldr.18
SystemTime      2018-10-23 08:30:51+00:00
NtSystemRoot    C:\Windows
```

### B. windows.pslist (key processes)

```
PID   PPID  ImageFileName   SessionId  CreateTime
324   1876  explorer.exe    1          2018-10-23 08:30:04 UTC
2096  324   cmd.exe         1          2018-10-23 08:30:18 UTC
2104  380   conhost.exe     1          2018-10-23 08:30:18 UTC
2412  324   DumpIt.exe      1          2018-10-23 08:30:48 UTC
2424  380   conhost.exe     1          2018-10-23 08:30:48 UTC
```

### C. windows.cmdline (key entries)

```
PID   Process     Args
2096  cmd.exe     "C:\Windows\system32\cmd.exe"
2412  DumpIt.exe  "C:\Users\hello\Desktop\DumpIt\DumpIt.exe"
```

### D. windows.hashdump

```
User           RID   lmhash                            nthash
Administrator  500   aad3b435b51404eeaad3b435b51404ee  31d6cfe0d16ae931b73c59d7e0c089c0
Guest          501   aad3b435b51404eeaad3b435b51404ee  31d6cfe0d16ae931b73c59d7e0c089c0
hello          1000  aad3b435b51404eeaad3b435b51404ee  101da33f44e92c27835e64322d72e8b7
```
