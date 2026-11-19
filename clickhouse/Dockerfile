# ClickHouse for OpenLIT traces, metrics and app tables (official image, pinned)
FROM clickhouse/clickhouse-server:26.8.41.14@sha256:4fcc05a5642c52250ab57a184bc0523a00ba5dcd4e8b43a918e7477b844f1048

# Upstream OpenLIT's log-trimming config and its idempotent table init script.
COPY openlit.xml /etc/clickhouse-server/config.d/openlit.xml
COPY --chmod=755 init-openlit.sh /docker-entrypoint-initdb.d/init-openlit.sh
ENV CLICKHOUSE_ALWAYS_RUN_INITDB_SCRIPTS=true \
    CLICKHOUSE_DB=openlit \
    CLICKHOUSE_DATABASE=openlit \
    CLICKHOUSE_USER=default
EXPOSE 8123 9000
