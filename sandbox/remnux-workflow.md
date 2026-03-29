# REMnux — Malware Analysis Workflow

## Setup

Pull the REMnux Docker image:

```bash
docker pull remnux/remnux-distro
```

Run an isolated container (no network by default):

```bash
docker run --rm -it --network none \
  -v $(pwd)/samples:/home/remnux/samples \
  remnux/remnux-distro bash
```

Place samples in `sandbox/samples/` on the host; they appear at
`/home/remnux/samples/` inside the container.

## Static analysis steps

All commands run inside the REMnux container unless noted.

### 1. File identification

```bash
file <sample>
xxd <sample> | head -40      # inspect magic bytes
strings <sample> | less
```

### 2. Hash and check

```bash
sha256sum <sample>
md5sum <sample>
# Cross-reference hash against VirusTotal manually (outside container)
```

### 3. PE analysis (Windows executables)

```bash
pecheck <sample>
pefile <sample>              # sections, imports, exports
pescanner <sample>
```

### 4. String extraction

```bash
strings -a -n 8 <sample> | grep -E "(http|cmd|powershell|reg)" | head -50
floss <sample>               # deobfuscated strings (FLOSS tool)
```

### 5. Packer / entropy check

```bash
peframe <sample>
```

High entropy sections (.text > 7.0) suggest packing or encryption.

## Memory dump capture

If running the sample in a controlled VM (not in REMnux directly), capture a
memory dump using the host hypervisor snapshot, then analyse with Volatility 3.

See `volatility/cheatsheet.md` for analysis commands.

## Output

Document findings in `sandbox/case-report.md` using the same structure as
Volatility case reports:

1. Sample metadata (hash, file type, size)
2. Static indicators (strings, imports, sections)
3. Memory artefacts (if dump available)
4. Conclusions and MITRE ATT&CK mapping
