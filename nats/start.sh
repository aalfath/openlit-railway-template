#!/bin/sh
# Writes nats.conf from upstream OpenLIT's assets/nats.conf, with the two
# passwords quoted from the environment, and listens on IPv4 and IPv6.
set -eu
: "${NATS_RECEIVER_PASSWORD:?NATS_RECEIVER_PASSWORD must be set}"
: "${NATS_ENGINE_PASSWORD:?NATS_ENGINE_PASSWORD must be set}"
case "${NATS_RECEIVER_PASSWORD}${NATS_ENGINE_PASSWORD}" in
  *\"*|*\\*) echo "NATS passwords must not contain quotes or backslashes" >&2; exit 1 ;;
esac
MON_PORT="${PORT:-8222}"
mkdir -p /etc/nats /data
cat > /etc/nats/nats.conf <<CONF
listen: "[::]:4222"
# Monitoring (healthz) for Railway's health check; private network only.
http: "[::]:${MON_PORT}"
max_payload: 1MB

jetstream {
  store_dir: "/data"
  max_file_store: ${NATS_MAX_FILE_STORE:-1GB}
  max_memory_store: 64MB
}

authorization {
  users: [
    {
      user: openlit-receiver
      password: "${NATS_RECEIVER_PASSWORD}"
      permissions: {
        publish: {
          allow: [
            "openlit.signal.>",
            "\$JS.API.STREAM.CREATE.OPENLIT_SIGNALS",
            "\$JS.API.STREAM.UPDATE.OPENLIT_SIGNALS",
            "\$JS.API.STREAM.INFO.OPENLIT_SIGNALS"
          ]
        }
        subscribe: { allow: ["_INBOX_RECEIVER.>"] }
      }
    },
    {
      user: openlit-engine
      password: "${NATS_ENGINE_PASSWORD}"
      permissions: {
        publish: {
          allow: [
            "\$JS.API.STREAM.INFO.OPENLIT_SIGNALS",
            "\$JS.API.CONSUMER.CREATE.OPENLIT_SIGNALS",
            "\$JS.API.CONSUMER.CREATE.OPENLIT_SIGNALS.>",
            "\$JS.API.CONSUMER.DELETE.OPENLIT_SIGNALS.>",
            "\$JS.API.CONSUMER.INFO.OPENLIT_SIGNALS.>",
            "\$JS.API.CONSUMER.MSG.NEXT.OPENLIT_SIGNALS.>"
          ]
        }
        subscribe: { allow: ["_INBOX_ENGINE.>"] }
      }
    }
  ]
}
CONF
exec nats-server -c /etc/nats/nats.conf
