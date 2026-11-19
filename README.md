[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/openlit?utm_medium=integration&utm_source=button&utm_campaign=openlit)

# OpenLIT on Railway

One-click [Railway](https://railway.com) template for [OpenLIT](https://github.com/openlit/openlit), the open-source, OpenTelemetry-native observability platform for LLM apps, AI agents, vector databases and GPUs.

It deploys **OpenLIT 2.1.1** with the full upstream stack, each part as its own Railway service built from this repo:

| Service | Folder | Image (pinned by version and digest) | What it does | Volume |
|---|---|---|---|---|
| **Gateway** | `gateway/` | `caddy:2.11.9-alpine` | The only public URL. Serves the OpenLIT UI and takes OTLP/HTTP data on `/v1/traces`, `/v1/metrics`, `/v1/logs`. Blocks self sign-up. | none |
| **OpenLIT** | `openlit/` | `ghcr.io/openlit/openlit:2.1.1` | Next.js UI and API, the OTLP receiver (4318 HTTP, 4317 gRPC on the private network) and the realtime rules engine. | `/app/client/data` (SQLite: users, projects, API keys, settings) |
| **ClickHouse** | `clickhouse/` | `clickhouse/clickhouse-server:26.8.41.14` | Stores traces, metrics, logs and OpenLIT's analytics tables. | `/var/lib/clickhouse` |
| **NATS** | `nats/` | `nats:2.15.3-alpine` | JetStream queue that feeds realtime signals from the receiver to the rules engine. | `/data` |

## After you deploy

1. Open the Gateway service's public URL and sign in as `user@openlit.io` with the password in the **OpenLIT** service's `OPENLIT_ADMIN_PASSWORD` variable (generated per deploy). To change it, change that variable: it is applied at every start. Keep the admin's email as it is, because OpenLIT's own seed recreates `user@openlit.io` when it is missing.
2. Create an API key in *Settings → API Keys*.
3. Point your app's OpenLIT SDK or any OpenTelemetry exporter at the Gateway URL, with the key as a bearer token:
   ```sh
   export OTEL_EXPORTER_OTLP_ENDPOINT="https://YOUR-GATEWAY-DOMAIN"
   export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer YOUR-OPENLIT-API-KEY"
   ```
   Services in the same Railway project can also send to `http://openlit.railway.internal:4318` (HTTP) or `:4317` (gRPC); the key is still required.

## Variables

All of them are filled in at deploy time; nothing has to be typed in.

| Service | Variable | Default | Notes |
|---|---|---|---|
| OpenLIT | `OPENLIT_ADMIN_PASSWORD` | generated secret | Password of `user@openlit.io`. Set at every start, so changing it here resets it. |
| OpenLIT | `INIT_DB_HOST`, `INIT_DB_PASSWORD` | references to ClickHouse | ClickHouse connection. |
| OpenLIT | `NATS_URL`, `NATS_RECEIVER_PASSWORD`, `NATS_ENGINE_PASSWORD` | references to NATS | Realtime signals. Remove `NATS_URL` to turn them off. |
| OpenLIT | `NEXTAUTH_URL` | `https://` + Gateway domain | Public URL used for sign-in callbacks. |
| ClickHouse | `CLICKHOUSE_PASSWORD` | generated secret | Password of the ClickHouse `default` user. |
| NATS | `NATS_RECEIVER_PASSWORD`, `NATS_ENGINE_PASSWORD` | generated secrets | One NATS user each for the receiver and the engine, with upstream's least-privilege permissions. |
| Gateway | `OPENLIT_HOST` | OpenLIT's private domain | Upstream for the UI and OTLP. |

To add teammates, invite them in *Settings → Organisation*, set `ALLOW_SIGNUP=true` on **Gateway** while they register, then remove it.

Optional, add them yourself: `ALLOW_SIGNUP=true` on **Gateway** opens self sign-up; `OTLP_REQUIRE_API_KEY=false` on **OpenLIT** accepts OTLP data without a key (not recommended on a public URL); `TELEMETRY_ENABLED=true` on **OpenLIT** sends anonymous usage data to the OpenLIT team (off by default here); `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` or `GITHUB_CLIENT_ID`/`GITHUB_CLIENT_SECRET` on **OpenLIT** enable OAuth sign-in.

## What differs from upstream's docker-compose

- The upstream seed creates `user@openlit.io` with a published default password. Here the password comes from a generated variable and is set before the seed runs (`openlit/start.sh`, `openlit/set-admin-password.js`).
- OTLP ingest needs an OpenLIT API key (`OTLP_REQUIRE_API_KEY=true`), because the Gateway makes it public.
- NATS passwords are generated instead of upstream's `change-me` defaults.
- ClickHouse is 26.8 LTS instead of 24.4; the log-trimming config was rewritten because 26.x rejects upstream's `<system_log>` element. The table init script is upstream's, unchanged.
- Upstream's anonymous telemetry is off by default.

## Updates

Each service builds from this repo's `main` branch. When we bump a pinned version, Railway shows an "update available" notice on your project, and you choose when to apply it. Read [CHANGELOG.md](CHANGELOG.md) first. Breaking changes are listed first in each entry. Your volumes are kept across updates. OpenLIT runs its own SQLite and ClickHouse migrations on start.

## Local test

```sh
export CH_PW=$(openssl rand -hex 16) NATS_RX_PW=$(openssl rand -hex 16) NATS_ENG_PW=$(openssl rand -hex 16) ADMIN_PW=$(openssl rand -hex 16)
docker compose -f test/compose.yml up --build
# then open http://localhost:8080 and sign in as user@openlit.io with $ADMIN_PW
```

## Licence

The wrapper files in this repo are MIT. OpenLIT is Apache-2.0; ClickHouse, NATS and Caddy keep their own licences.
