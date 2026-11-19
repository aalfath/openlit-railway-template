# NATS with JetStream for OpenLIT's realtime signals (official image, pinned)
FROM nats:2.15.3-alpine@sha256:558394a23dd3c36f2d3a64b51865fd09908010e80a542cea5e75c2af543ed62a

COPY start.sh /usr/local/bin/openlit-nats-start
RUN chmod 755 /usr/local/bin/openlit-nats-start
EXPOSE 4222 8222
ENTRYPOINT ["/usr/local/bin/openlit-nats-start"]
