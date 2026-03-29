# Splunk — Setup

## Starting Splunk

```bash
cd splunk/
docker compose up -d
```

Wait ~60 seconds for Splunk to initialise, then open:

```
http://localhost:8000
```

Login: `admin` / `changeme123!`
(Change the password immediately after first login.)

## Log ingestion

### Option A — HTTP Event Collector (HEC)

Enable HEC in Splunk UI: Settings → Data Inputs → HTTP Event Collector → New Token.

Send logs:

```bash
curl -k https://localhost:8088/services/collector/event \
  -H "Authorization: Splunk <HEC_TOKEN>" \
  -d '{"event": "test log line", "sourcetype": "syslog"}'
```

### Option B — Monitor a local file (via volume mount)

Mount the log file into the container and add a `inputs.conf` entry:

```ini
[monitor:///var/log/auth.log]
index = main
sourcetype = linux_secure
```

On NixOS, journal logs can be exported:

```bash
journalctl -f -o json > /tmp/journal-stream.json
```

Then ingest via HEC or a monitored file mount.

## Searching

Basic search in Search & Reporting:

```spl
index=main | head 20
```

Verify log ingestion:

```spl
index=main earliest=-15m | stats count by sourcetype
```

## Detection rules

Saved searches and alert rules are stored as `.conf` files in
`splunk/detections/`. Each file is annotated with the MITRE ATT&CK technique
it covers.

To load a saved search manually:
Settings → Searches, Reports, and Alerts → New Alert.
