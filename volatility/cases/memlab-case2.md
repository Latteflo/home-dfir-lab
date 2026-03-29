# MemLabs Lab 2 — Incident Investigation Report

## Case Metadata

| Field | Value |
|---|---|
| Case reference | MEMLABS-LAB2 |
| Analysis date | 2026-03-29 |
| Analyst | Home DFIR Lab |
| Tool | Volatility 3 Framework 2.11.0 |
| Dump file | MemoryDump_Lab2.raw |
| OS identified | Windows 7 SP1 x64 (Build 7601.17514.amd64fre.win7sp1_rtm) |
| System time at capture | 2019-12-14 10:38:46 UTC |
| Capture tool | DumpIt.exe (PID 3844, run by user SmartNet) |

---

## Executive Summary

This Windows 7 SP1 memory dump contains two concurrent user sessions. The
primary area of forensic interest is `KeePass.exe` (PID 3008), running under
Session 1 (`SmartNet`) with a password database located at
`C:\Users\SmartNet\Secrets\Hidden.kdbx` as its argument. A second notable
finding is `notepad.exe` (PID 3260) simultaneously opening the same `.kdbx`
file — a binary database format that has no meaningful text representation —
suggesting a deliberate attempt to examine the raw file content. Google Chrome
(version 79) was active in Session 2 with a recently closed connection to a
Google server. NTLM credential hashes were recovered for all five local
accounts.

---

## Investigation Methodology

| Plugin | Purpose |
|---|---|
| `windows.info` | Confirm OS version and dump integrity |
| `windows.pslist` | Enumerate all processes visible in the EPROCESS list |
| `windows.pstree` | Reconstruct parent-child process relationships |
| `windows.cmdline` | Recover command-line arguments for each process |
| `windows.netscan` | Identify network connections and listening sockets |
| `windows.filescan` | Enumerate file objects cached in memory |
| `windows.hashdump` | Extract NTLM credential hashes from the SAM hive |

---

## Findings

### Process Analysis

Two concurrent user sessions were active at capture time: Session 1 (`SmartNet`)
and Session 2 (a second user). Each had its own `explorer.exe`, `csrss.exe`,
`winlogon.exe`, `dwm.exe`, and `taskhost.exe`.

**Session 1 — SmartNet (Session ID 1)**

| PID | Process | Parent | Notes |
|---|---|---|---|
| 1064 | explorer.exe | 2004 (WmiApSrv.exe) | Desktop shell — unusual parent (see below) |
| 3008 | KeePass.exe | 1064 (explorer) | Opening `Hidden.kdbx` from Secrets folder |
| 3260 | notepad.exe | 3180 | Opening the same `.kdbx` file |
| 3844 | DumpIt.exe | 1064 (explorer) | Memory capture tool; produced this dump |
| 1896 | VBoxTray.exe | 1064 (explorer) | VirtualBox guest agent (expected) |

**Anomaly — explorer.exe parent process:**
`explorer.exe` (PID 1064) shows `WmiApSrv.exe` (PID 2004) as its parent rather
than the expected `userinit.exe`. While parent PID fields can be unreliable in
memory forensics due to PID reuse, this relationship is worth noting. All other
indicators for `explorer.exe` (path, command line, session) appear legitimate.

**KeePass.exe (PID 3008):**
```
"C:\Program Files (x86)\KeePass Password Safe 2\KeePass.exe"
"C:\Users\SmartNet\Secrets\Hidden.kdbx"
```
KeePass Password Safe is a legitimate credential management application. The
database is stored in a folder named `Secrets` under the user profile rather
than the default KeePass location, which may indicate deliberate concealment.
KeePass configuration files were found in memory for both `SmartNet` and
`Alissa Simpson`, suggesting both users have KeePass databases.

**notepad.exe (PID 3260):**
```
"C:\Windows\system32\NOTEPAD.EXE" C:\Users\SmartNet\Secrets\Hidden.kdbx
```
Opening a `.kdbx` file in Notepad is atypical. The KeePass database format is
binary; it yields no readable text in a standard text editor. This action
suggests either: (a) an analyst examining raw file bytes to identify structure
or embedded strings, or (b) a user unfamiliar with the format attempting to
view it. The file was opened 24 seconds before `DumpIt.exe` ran (notepad at
10:38:20, DumpIt at 10:38:43), indicating both events occurred in close
temporal proximity.

**Session 2 (Session ID 2)**

| PID | Process | Parent | Notes |
|---|---|---|---|
| 2664 | explorer.exe | 2632 | Desktop shell for second session |
| 2296 | chrome.exe | 2664 | Google Chrome 79.0.3945.79 (main process) |
| 2304, 2476, 2572, 1632, 2964 | chrome.exe | 2296 | Chrome subprocesses (crashpad, renderer, GPU, utility, watcher) |
| 2096 | cmd.exe | 2664 | Command prompt open |
| 2792 | VBoxTray.exe | 2664 | VirtualBox guest agent (expected) |

Chrome's crashpad handler reveals the user data path:
`C:\Users\SmartNet\AppData\Local\Google\Chrome\User Data`, meaning Chrome in
Session 2 also runs under the `SmartNet` profile — both sessions belong to the
same Windows account accessed via Fast User Switching or a second interactive
logon.

---

### Network Connections

| Owner | Remote Address | Port | State | Notes |
|---|---|---|---|---|
| chrome.exe (PID 2964) | `172.217.166.110` | 443 | CLOSED | Google server (confirmed Google ASN) |
| chrome.exe (PID 2964) | `56.203.218.1` | — | CLOSED | Unresolved external IP |
| chrome.exe (multiple) | mDNS `5353` | UDP | — | Local network discovery |
| System (PID 4) | `127.0.0.1:2869` | TCP | ESTABLISHED | UPnP loopback (wmpnetwk.exe ↔ System) |

Chrome had recently closed connections to Google servers, consistent with
normal browser activity (updates, telemetry, or web browsing). The IP
`56.203.218.1` could not be resolved to a known service from this dump alone.
No active outbound connections to suspicious external hosts were present at
capture time.

---

### Command History

`cmd.exe` (PID 2096) ran in Session 2 with no arguments beyond the executable
path. No additional history recoverable from this plugin alone.

---

### Credential Artefacts

| Username | RID | NT Hash | Notes |
|---|---|---|---|
| Administrator | 500 | `31d6cfe0d16ae931b73c59d7e0c089c0` | Empty password (disabled) |
| Guest | 501 | `31d6cfe0d16ae931b73c59d7e0c089c0` | Empty password (disabled) |
| SmartNet | 1001 | `4943abb39473a6f32c11301f4987e7e0` | Active; matches Lab 1 hash |
| HomeGroupUser$ | 1002 | `f0fc3d257814e08fea06e63c5762ebd5` | Service account |
| Alissa Simpson | 1003 | `f4ff64c8baac57d22f22edc681055ba6` | Active; matches Lab 1 hash |

Hashes are identical to those recovered in MemLabs Lab 1, confirming this is
the same system image at a different point in time. Passwords have not changed
between captures.

---

### Files of Interest

| Path | Significance |
|---|---|
| `C:\Users\SmartNet\Secrets\Hidden.kdbx` | KeePass database actively open in both KeePass and Notepad |
| `C:\Users\SmartNet\AppData\Roaming\KeePass\KeePass.config.xml` | KeePass configuration for SmartNet |
| `C:\Users\Alissa Simpson\AppData\Roaming\KeePass\KeePass.config.xml` | KeePass configuration also present for Alissa Simpson |
| `C:\Program Files (x86)\KeePass Password Safe 2\KeePass.exe` | KeePass installation; multiple handles in memory |
| Chrome User Data | `C:\Users\SmartNet\AppData\Local\Google\Chrome\User Data\` — browsing history, saved passwords potentially accessible |

---

## Indicators of Compromise

| Type | Value | Significance |
|---|---|---|
| Process | `KeePass.exe` (PID 3008) with `Hidden.kdbx` | Password database in non-standard `Secrets` folder actively open at capture |
| Process | `notepad.exe` (PID 3260) opening `Hidden.kdbx` | Binary credential store opened in a text editor — analytical or evasive action |
| File | `C:\Users\SmartNet\Secrets\Hidden.kdbx` | KeePass database at non-default path; name suggests intentional obfuscation |
| Process | `DumpIt.exe` (PID 3844) | Deliberate memory acquisition 23 seconds after notepad opened the `.kdbx` |
| Network | `56.203.218.1` (Chrome, CLOSED) | Unresolved external IP contacted by Chrome prior to capture |
| Credential | NT hash `4943abb39473a6f32c11301f4987e7e0` (SmartNet) | Unchanged from Lab 1; offline cracking applicable |

---

## Conclusions

The defining characteristic of this dump is the KeePass password database
`Hidden.kdbx`, stored in a folder named `Secrets` and open in both KeePass and
Notepad simultaneously. The Notepad access is anomalous: `.kdbx` is a binary
format and opening it in a text editor yields no readable content under normal
circumstances, but may expose partial plaintext strings (entry titles, URLs)
embedded in unencrypted metadata regions. The tight temporal window — Notepad
opened the file at 10:38:20, DumpIt ran at 10:38:43 — suggests this session was
set up deliberately to capture the state of the credential store in memory.

Both user accounts (`SmartNet` and `Alissa Simpson`) have KeePass configuration
files present in memory, meaning both accounts use KeePass and both
configurations could yield vault locations for further investigation.

No evidence of external compromise or malware was identified. Activity is
consistent with a credential-focused forensic exercise.

---

## Appendix — Raw Command Outputs

### A. windows.info

```
Variable        Value
Kernel Base     0xf80002601000
NTBuildLab      7601.17514.amd64fre.win7sp1_rtm.
SystemTime      2019-12-14 10:38:46+00:00
NtSystemRoot    C:\Windows
```

### B. windows.pslist (key processes)

```
PID   PPID  ImageFileName   SessionId  Wow64  CreateTime
1064  2004  explorer.exe    1          False  2019-12-14 10:36:05 UTC
3008  1064  KeePass.exe     1          False  2019-12-14 10:37:56 UTC
3260  3180  notepad.exe     1          False  2019-12-14 10:38:20 UTC
3844  1064  DumpIt.exe      1          True   2019-12-14 10:38:43 UTC
2664  2632  explorer.exe    2          False  2019-12-14 10:36:29 UTC
2296  2664  chrome.exe      2          False  2019-12-14 10:36:45 UTC
2096  2664  cmd.exe         2          False  2019-12-14 10:36:35 UTC
```

### C. windows.cmdline (key entries)

```
PID   Process      Args
3008  KeePass.exe  "C:\Program Files (x86)\KeePass Password Safe 2\KeePass.exe" "C:\Users\SmartNet\Secrets\Hidden.kdbx"
3260  notepad.exe  "C:\Windows\system32\NOTEPAD.EXE" C:\Users\SmartNet\Secrets\Hidden.kdbx
3844  DumpIt.exe   "C:\Users\SmartNet\Downloads\DumpIt\DumpIt.exe"
2096  cmd.exe      "C:\Windows\system32\cmd.exe"
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
Proto   RemoteAddr        Port  State      PID   Owner
TCPv4   172.217.166.110   443   CLOSED     2964  chrome.exe
TCPv4   56.203.218.1      —     CLOSED     2964  chrome.exe
UDPv4   5353 (mDNS)             —          2296  chrome.exe
```
