#!/bin/sh
# Writes the Caddyfile and runs Caddy.
#   /v1/traces, /v1/metrics, /v1/logs -> OpenLIT OTLP/HTTP receiver (port 4318)
#   everything else                   -> OpenLIT UI (port 3000)
# Self sign-up is closed unless ALLOW_SIGNUP=true.
set -eu
: "${OPENLIT_HOST:?OPENLIT_HOST must be set to the OpenLIT service's private domain}"
PORT="${PORT:-8080}"
UI="${OPENLIT_HOST}:${OPENLIT_UI_PORT:-3000}"
OTLP="${OPENLIT_HOST}:${OPENLIT_OTLP_PORT:-4318}"

if [ "${ALLOW_SIGNUP:-false}" = "true" ]; then
  SIGNUP='	# ALLOW_SIGNUP=true: anyone who can reach this URL can create an account'
else
  SIGNUP='	@signup path /register /register/* /api/auth/signin/register /api/auth/callback/register
	handle @signup {
		respond "Sign-up is closed on this OpenLIT instance. Set ALLOW_SIGNUP=true on the Gateway service to open it." 403
	}'
fi

cat > /etc/caddy/Caddyfile <<CADDY
{
	auto_https off
	admin off
	servers {
		trusted_proxies static private_ranges
	}
}

:${PORT} {
	handle /gateway-health {
		respond "ok" 200
	}
${SIGNUP}
	@otlp path /v1/traces /v1/metrics /v1/logs
	handle @otlp {
		request_body {
			max_size 32MB
		}
		reverse_proxy ${OTLP}
	}
	handle {
		reverse_proxy ${UI} {
			header_up X-Forwarded-Proto https
		}
	}
}
CADDY
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
