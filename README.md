# Home DFIR Lab

A structured, hands-on Digital Forensics and Incident Response lab built to
develop and demonstrate practical blue-team skills: memory forensics with
Volatility 3, log-based threat detection with Splunk SIEM, and malware analysis
in an isolated Linux sandbox.

This lab was built to back up claims made in job applications with real,
documented, reproducible work — not certificates.

## What this lab demonstrates

| Competency | Implementation |
|---|---|
| Memory forensics | Volatility 3 analysis of real memory dumps (MemLabs cases) |
| SIEM detection engineering | Splunk running on Docker, ingesting live logs, with saved detection rules |
| Malware analysis workflow | REMnux-based static analysis pipeline with documented outputs |
| Incident reporting | Structured case reports modelled on professional IR methodology |

## Structure

- [`volatility/`](volatility/) — Volatility 3 setup, command reference, and case investigations
- [`splunk/`](splunk/) — Docker Compose deployment, detection rules as `.conf` files
- [`sandbox/`](sandbox/) — REMnux static analysis workflow

## Case investigations

| Case | Artefacts Recovered | Report |
|---|---|---|
| MemLabs Lab 1 | Process tree (2 sessions), NTLM hashes (5 accounts), WinRAR archive artefact, DumpIt.exe capture chain | [Report](volatility/cases/memlab-case1.md) |
| MemLabs Lab 2 | KeePass database (`Hidden.kdbx`) in memory, Notepad opening binary credential store, NTLM hashes | [Report](volatility/cases/memlab-case2.md) |
| MemLabs Lab 3 | `evilscript.py` on Desktop, dual Notepad review, msiexec installation artefacts, x86 PAE image | [Report](volatility/cases/memlab-case3.md) |
| Challenge | Active cmd.exe session, minimal process set, NT hash rotation confirmed vs Lab 3 | [Report](volatility/cases/challenge-case.md) |

## Detection rules (Splunk)

| Rule | Technique | File |
|---|---|---|
| SSH brute force | T1110.001 | [`ssh_brute_force.conf`](splunk/detections/ssh_brute_force.conf) |
| Sudo privilege escalation | T1548.003 | [`sudo_escalation.conf`](splunk/detections/sudo_escalation.conf) |
| Repeated failed logins | T1078 | [`repeated_failed_logins.conf`](splunk/detections/repeated_failed_logins.conf) |

## Environment

- OS: NixOS (flake-based)
- Runtime: Docker (no Windows VMs; all sandboxing is Linux-native)
- Forensics: Volatility 3 via nix-shell + Python
- SIEM: Splunk Enterprise (Docker Compose)
- Sandbox: REMnux Docker image

## Status

See [PROGRESS.md](PROGRESS.md) for a detailed checklist of completed and
pending work.
