# Log Management

## Default Driver Risk

Docker's default log driver (`json-file`) writes
unbounded log files under
`/var/lib/docker/containers/<id>/`. A single
chatty service will fill the disk. Set size limits
globally in `daemon.json` (see
`references/config.md`) and per-service in
compose.yaml:

```yaml
services:
  app:
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"
```

Per-container settings override the daemon
default. Add this to any service known to produce
high log volume. Do it at deploy time — after the
disk is full, you cannot write the fix.

Existing log files are not truncated when limits
are added. After recreating the container, delete
the old log file manually if needed.

## Identifying Chatty Containers

When disk usage grows from
`/var/lib/docker/containers/` rather than volumes
or images:

```bash
# Find the largest log files on the host
find /var/lib/docker/containers \
  -name '*-json.log' \
  -exec du -sh {} + | sort -rh | head -10
```

Match the container ID prefix to a name with
`docker ps` or `docker inspect`. The offending
service gets a `logging:` block added in
compose.yaml and is recreated.

## journald Driver

Setting `log-driver: journald` in `daemon.json`
eliminates the disk fill problem — systemd-
journald handles rotation, and `docker logs`
continues to work. Container logs appear in
`journalctl` alongside system logs.

Limitation: `docker logs` requires the daemon to
be local. If you access container logs remotely
via the Docker API or a log aggregator reading
log files, `journald` is not compatible — use
`json-file` with size limits instead.

## Structured Logging

Containers that emit JSON to stdout are easier to
filter, ship, and query in a centralized system.
A plain text line cannot be queried by field; a
JSON log line can.

- Emit JSON when the framework supports it (most
  do: `--log-format json`, `LOG_FORMAT=json`).
- Include a `level` field so downstream filters
  can drop debug noise in production.
- Accept a `LOG_LEVEL` environment variable so
  verbosity can be tuned per deployment without
  rebuilding the image.

## Centralized Logging

### Loki + Grafana Alloy

Lightweight. Alloy (successor to Promtail) runs
as a container, reads Docker logs via the Docker
API or log files, and ships to Loki. Integrates
naturally with Grafana dashboards.

Good fit for deployments already using Grafana
for metrics. Low resource use — Loki stores logs
as compressed chunks indexed by labels, not by
content.

Limitation: Loki is optimized for label-based
filtering, not full-text search. If you need
`grep`-style search across all log content,
consider Elasticsearch.

### Fluent Bit

~5 MB RAM, fast. Reads from multiple sources
(Docker API, log files, systemd), transforms and
routes to multiple backends (Loki, Elasticsearch,
S3, HTTP endpoints). Good when aggregating logs
from several servers or keeping backend options
open.

### ELK Stack

Full-text search, complex queries, powerful
alerting. Elasticsearch requires several GB of
RAM — the full ELK stack is a significant
operational commitment. Worth it when log search
is a primary tool, not when the goal is simply
preventing disk fill.

## Log Driver Integration

Docker's `fluentd` and `gelf` log drivers route
logs from the daemon directly to a remote
endpoint, bypassing local log files entirely. No
disk space is used on the host.

Critical setting when using a remote log driver:

```yaml
services:
  app:
    logging:
      driver: fluentd
      options:
        mode: non-blocking
        max-buffer-size: "4m"
```

The default `mode: blocking` causes container
start to hang if the log endpoint is unavailable.
`non-blocking` with a buffer prevents a logging
outage from becoming a service outage.
