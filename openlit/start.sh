#!/bin/bash
# Railway start script for OpenLIT. Runs before the image's own entrypoint.
set -euo pipefail

: "${OPENLIT_ADMIN_PASSWORD:?OPENLIT_ADMIN_PASSWORD must be set (the template generates it)}"
if [ "${#OPENLIT_ADMIN_PASSWORD}" -lt 12 ] || [ "${OPENLIT_ADMIN_PASSWORD}" = "openlituser" ]; then
  echo "[openlit-railway] OPENLIT_ADMIN_PASSWORD must be at least 12 characters and not the upstream default" >&2
  exit 1
fi

# Fixed settings (override any of them with a service variable).
export DOCKER_PORT="${PORT:-3000}"
# "::" listens on IPv4 and IPv6, so Railway's private network reaches the UI.
export HOSTNAME="::"
export SQLITE_DATABASE_URL="${SQLITE_DATABASE_URL:-file:/app/client/data/data.db}"
export INIT_DB_PORT="${INIT_DB_PORT:-8123}"
export INIT_DB_USERNAME="${INIT_DB_USERNAME:-default}"
export INIT_DB_DATABASE="${INIT_DB_DATABASE:-openlit}"
export NATS_RECEIVER_USER="${NATS_RECEIVER_USER:-openlit-receiver}"
export NATS_ENGINE_USER="${NATS_ENGINE_USER:-openlit-engine}"
# OTLP ingest needs an OpenLIT API key (Authorization: Bearer <key>).
export OTLP_REQUIRE_API_KEY="${OTLP_REQUIRE_API_KEY:-true}"
# Anonymous usage telemetry to the OpenLIT team is off unless you set it to true.
export TELEMETRY_ENABLED="${TELEMETRY_ENABLED:-false}"

# An empty reference (no public domain yet) renders as "https://", which breaks
# NextAuth. Without NEXTAUTH_URL, OpenLIT derives the URL from each request.
case "${NEXTAUTH_URL:-}" in
  ""|"https://"|"http://") unset NEXTAUTH_URL ;;
esac

cd /app/client
export PATH="/app/client/node_modules/.bin:${PATH}"
mkdir -p /app/client/data
chmod 700 /app/client/data

# ClickHouse migrations run once when the UI server starts, so wait for it.
node /opt/openlit-railway/wait-clickhouse.js || echo "[openlit-railway] continuing without ClickHouse; it will be retried by the app" >&2

# Create the SQLite schema, then create or update the admin account before the
# upstream seed runs, so the upstream default password is never set.
prisma migrate deploy
node /opt/openlit-railway/set-admin-password.js

exec /app/client/scripts/entrypoint.sh
