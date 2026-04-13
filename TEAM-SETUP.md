# Local Elastic Stack — Team Setup Guide

Spins up a full Elastic stack locally using Docker: Elasticsearch, Kibana, Fleet, APM, and Detection Engine — all TLS-secured and pre-configured.

Repo: https://github.com/TomonoriSoejima/elastic-container (branch: `apm-local-setup`)

---

## Prerequisites

- macOS (Intel or Apple Silicon)

---

## Setup

```bash
git clone https://github.com/TomonoriSoejima/elastic-container
cd elastic-container
```

Edit `.env` and set your passwords (replace `changeme`):

```
ELASTIC_PASSWORD=yourpassword
KIBANA_PASSWORD=yourpassword
```

If you have an internal Elastic Platinum license, copy it to the repo root (internal staff can get one from [this Confluence page](https://elasticco.atlassian.net/wiki/spaces/PM/pages/46802910/Internal+License+-+X-Pack+and+Endgame#Stack-Licenses)):

```bash
cp ~/Downloads/license-release-stack-platinum.json .
```

Start the stack:

```bash
chmod +x elastic-container.sh
./elastic-container.sh start
```

Wait for `READY SET GO!` — then browse to **https://localhost:5601**

> Accept the browser TLS warning (self-signed cert) by typing `thisisnotsafe` or clicking through.

Login: `elastic` / `<your ELASTIC_PASSWORD>`

### Forgot your password?

If you forget the `elastic` user password, reset it from the running container:

```bash
docker exec ecp-elasticsearch \
  /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -b
```

This prints a new password (look for `New value:`). Verify it works:

```bash
curl -k -s -u 'elastic:<new_password>' \
  https://localhost:9200/_security/_authenticate | jq -r '.username'
```

If successful, it returns `elastic`. Then update `.env`:

```dotenv
ELASTIC_PASSWORD=<new_password>
```

---

## Enrolling an Elastic Agent

This is the main use case — enrolling an agent into your local Fleet Server.

### 1. Get the enrollment token

```bash
curl -k -s -u elastic:<ELASTIC_PASSWORD> \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: xx" \
  "https://localhost:5601/api/fleet/enrollment_api_keys" | jq '.list[] | {name, api_key, policy_id}'
```

Pick the token matching the agent policy you want to enroll into.

---



APM Server is running on **http://localhost:8200**.

Get your connection details from Kibana:  
**Observability → APM → Add data → Choose policy → Endpoint Policy**

| Setting | Value |
|---|---|
| `server_url` | `http://localhost:8200` |
| `secret_token` | shown in Kibana UI under Endpoint Policy |
| `environment` | `my-environment` |

### Test it end-to-end

There's a minimal Python Flask app that sends traces to APM via OpenTelemetry: [`apm-test/`](apm-test/)

Before running, update the `secret_token` in `run-local.sh` to match the one from Kibana (**Endpoint Policy**):

```bash
# in run-local.sh, update this line:
OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer <your_secret_token>" \
```

Then run:

```bash
cd apm-test
./run-local.sh
# then hit http://localhost:8080/test to generate a trace
```

Or via Docker (token injected at runtime):

```bash
docker build -t apm-test .
docker run -p 8080:8080 \
  -e OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer <your_secret_token>" \
  apm-test
```

Check **Observability → APM → Services** in Kibana — you should see `tomo-apm-test` appear within a few seconds.

---

## Notes

- First run is slow — Docker needs to pull images (~3–4 GB)
- Subsequent starts are fast (images cached)
- `license-release-stack-platinum.json` is gitignored — each person needs their own copy from the internal license portal
- After `destroy`, the license is re-applied automatically on next `start` if the file is present

### Fleet setup gotcha

Fleet Server needs extra time to fully initialize. The script waits 40 seconds after containers start before configuring Fleet, but on the **first ever run** (fresh volumes) it can take longer.

If Fleet shows as "not initialized" in Kibana after startup, just wait a minute and re-run:

```bash
./elastic-container.sh restart
```

Or check Fleet status in Kibana under **Fleet → Agents** — once Fleet Server shows as **Healthy**, everything is ready.

---

For all other commands and options, see the [upstream README](https://github.com/peasead/elastic-container/blob/main/README.md).
