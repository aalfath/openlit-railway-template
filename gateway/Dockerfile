# Public entry for OpenLIT: UI and OTLP/HTTP on one HTTPS domain (official Caddy, pinned)
FROM caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0

COPY start.sh /usr/local/bin/openlit-gateway-start
RUN chmod 755 /usr/local/bin/openlit-gateway-start
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/openlit-gateway-start"]
