# Lab Progress

## Pillar 1 — Volatility Memory Forensics

### Setup
- [x] Volatility 3 installed and verified (`vol -h`)
- [x] `volatility/setup.md` written (includes NixOS symbol-dir workaround)
- [x] `volatility/cheatsheet.md` written

### Case 1 — MemLabs Lab 1
- [x] Memory dump downloaded and verified
- [x] Process tree extracted and analysed
- [x] Network connections reconstructed
- [x] Suspicious artefacts identified
- [x] Incident report written: `volatility/cases/memlab-case1.md`

### Case 2 — MemLabs Lab 2
- [x] Memory dump downloaded and verified
- [x] Process tree extracted and analysed
- [x] Network connections reconstructed
- [x] Suspicious artefacts identified
- [x] Incident report written: `volatility/cases/memlab-case2.md`

### Case 3 — MemLabs Lab 3
- [x] Memory dump downloaded and verified
- [x] Process tree extracted and analysed
- [x] Network connections reconstructed
- [x] Suspicious artefacts identified
- [x] Incident report written: `volatility/cases/memlab-case3.md`

### Case 4 — Challenge
- [x] Memory dump downloaded and verified
- [x] Process tree extracted and analysed
- [x] Network connections reconstructed
- [x] Suspicious artefacts identified
- [x] Incident report written: `volatility/cases/challenge-case.md`

---

## Pillar 2 — Splunk SIEM

### Setup
- [x] `splunk/docker-compose.yml` written and tested
- [x] Splunk accessible at localhost:8000
- [x] `.env` / `.env.example` secrets handling in place
- [x] `splunk/setup.md` written

### Log ingestion
- [x] NixOS journal logs ingested via HEC (360 events)
- [x] Synthetic auth events sent for detection testing
- [x] Index confirmed via Search & Reporting

### Detection rules
- [x] SSH brute force rule — `splunk/detections/ssh_brute_force.conf` (T1110.001)
- [x] Sudo privilege escalation rule — `splunk/detections/sudo_escalation.conf` (T1548.003)
- [x] Repeated failed login rule — `splunk/detections/repeated_failed_logins.conf` (T1078)
- [x] All rules verified returning results against test data

### Documentation
- [ ] Dashboard screenshot saved: `splunk/screenshots/`
- [ ] Each rule documented with MITRE ATT&CK technique reference

---

## Pillar 3 — Malware Sandbox

### Setup
- [ ] REMnux Docker image pulled and running
- [ ] `sandbox/remnux-workflow.md` written

### Analysis workflow
- [ ] Sample selected (safe, public malware sample)
- [ ] Static analysis run inside REMnux container
- [ ] Memory dump captured
- [ ] Volatility analysis run on dump
- [ ] Full end-to-end report written: `sandbox/case-report.md`

---

## Final checks
- [ ] README.md tables updated with completed case links
- [ ] All reports proofread for professional presentation
- [ ] Repo pushed and public (or ready to share as-is for interviews)
