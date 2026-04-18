## Scheduling in Containers

Running a cron-like scheduler inside a container
keeps the schedule with the stack rather than on
the host. The two common choices are busybox
`crond` and supercronic.

## busybox crond

Available in any Alpine-based image — no extra
binary needed.

Limitations in a container context:
- Job stdout/stderr is discarded by default;
  output does not appear in `docker logs` without
  explicit redirection in the crontab command.
- Crontab must be written to a file before crond
  starts, which makes the entrypoint a shell
  heredoc — fragile and hard to read.
- Not designed to be PID 1. It will not reap
  zombie processes left by jobs that spawn and
  detach child processes. Always pair with tini
  (`init: true` in compose.yaml).
- Minimum granularity is 1 minute. Busybox crond
  also has minor syntax differences from vixie
  cron (e.g. `%` in commands is treated
  differently).

Right choice when the base image already ships
busybox (e.g. postgres:XX-alpine) and the job is
simple — avoiding an extra binary download
outweighs the limitations.

## supercronic

A single static binary built specifically for
containers:
- Job output goes to stdout/stderr and appears
  in `docker logs`.
- Handles SIGTERM cleanly: waits for the running
  job to finish before exiting.
- Standard crontab syntax with second-level
  support and clear error messages.

PID 1 caveat: supercronic handles its own direct
child processes correctly, but orphaned
grandchildren (spawned by a job script and then
detached) are not reaped. For scripts that spawn
background processes, add tini in front of
supercronic too.

Installation: supercronic is not in any standard
base image. Add it to the image that has the
tools the job needs — do not use the standalone
supercronic image, which ships only the
scheduler binary and lacks everything else
(pg_dump, shell utilities, etc.):

```dockerfile
FROM postgres:16-alpine
ARG SUPERCRONIC_VERSION=0.2.33
RUN wget -O /usr/local/bin/supercronic \
  https://github.com/aptible/supercronic/\
releases/download/v${SUPERCRONIC_VERSION}/\
supercronic-linux-amd64 \
  && chmod +x /usr/local/bin/supercronic
COPY crontab /etc/supercronic/crontab
ENTRYPOINT ["supercronic", \
  "/etc/supercronic/crontab"]
```

Right choice when job output visibility matters,
the job is complex, or you want clean SIGTERM
handling without shell glue.

## tini and PID 1

Neither crond nor supercronic is a substitute
for a proper init. For any scheduler container
that runs shell scripts or spawns subprocesses,
add tini:

```yaml
services:
  backup:
    init: true   # prepends tini as PID 1
```

See `references/images.md` for the full PID 1
and zombie-reaping discussion.
