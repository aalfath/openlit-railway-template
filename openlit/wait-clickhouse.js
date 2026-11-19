// Waits up to WAIT_CLICKHOUSE_SECONDS (default 180) for ClickHouse's /ping.
const host = process.env.INIT_DB_HOST;
const port = process.env.INIT_DB_PORT || "8123";
const limit = Number(process.env.WAIT_CLICKHOUSE_SECONDS || 180);
if (!host) {
  console.error("[openlit-railway] INIT_DB_HOST is not set; not waiting for ClickHouse");
  process.exit(1);
}
const h = host.includes(":") && !host.startsWith("[") ? `[${host}]` : host;
const url = `http://${h}:${port}/ping`;
const start = Date.now();
(async () => {
  for (;;) {
    try {
      const res = await fetch(url, { signal: AbortSignal.timeout(3000) });
      if (res.ok) {
        console.log(`[openlit-railway] ClickHouse is up (${url})`);
        process.exit(0);
      }
    } catch (e) {}
    if ((Date.now() - start) / 1000 > limit) {
      console.error(`[openlit-railway] ClickHouse did not answer ${url} within ${limit}s`);
      process.exit(1);
    }
    await new Promise((r) => setTimeout(r, 2000));
  }
})();
