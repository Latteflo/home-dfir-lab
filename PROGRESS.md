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
- [ ] `splunk/docker-compose.yml` written and tested
- [ ] Splunk accessible at localhost:8000
- [ ] `splunk/setup.md` written

### Log ingestion
- [ ] NixOS journal or auth logs flowing into Splunk
- [ ] Index confirmed via Search & Reporting

### Detection rules
- [ ] SSH brute force rule created and saved as `.conf`
- [ ] Sudo privilege escalation rule created and saved as `.conf`
- [ ] Repeated failed login rule created and saved as `.conf`
- [ ] All rules trigger correctly on test data

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
