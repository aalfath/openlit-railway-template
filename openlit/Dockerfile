# OpenLIT: UI + OTLP receiver + realtime engine (official image, pinned by version and digest)
FROM ghcr.io/openlit/openlit:2.1.1@sha256:259a4c97a3cc0ad6f5431dbbb74240cdf8870ed3908897f3adfe3a424c2eae80

# Small Railway wrapper: waits for ClickHouse, sets the admin password from
# OPENLIT_ADMIN_PASSWORD, then runs the image's own entrypoint.
WORKDIR /opt/openlit-railway
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --no-audit --no-fund && npm cache clean --force
COPY start.sh set-admin-password.js wait-clickhouse.js ./
RUN chmod 755 start.sh

WORKDIR /app/client
EXPOSE 3000 4317 4318
CMD ["/opt/openlit-railway/start.sh"]
