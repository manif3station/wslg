# Testing

## Policy

- tests run only inside Docker
- the shared test container definition lives at the workspace root
- this skill keeps its test files in `t/`

## Commands

```bash
docker compose -f ~/projects/skills/docker-compose.testing.yml run --rm perl-test bash -lc 'cd /workspace/skills/wslg && prove -lvr t'
docker compose -f ~/projects/skills/docker-compose.testing.yml run --rm perl-test bash -lc 'cd /workspace/skills/wslg && rm -rf cover_db /workspace/cover_db/* && HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lvr t && cover -report text'
```

## Latest Result

- Docker functional tests passed: `Files=4, Tests=114`
- Docker coverage passed for `lib/WSLg/Setup.pm`:
  - `100.0%` statement coverage
  - `100.0%` subroutine coverage
- Proven behaviors:
  - `dashboard wslg.setup` applies the Ubuntu `24.04` command plan, service file, and GNOME override path
  - `dashboard wslg.desktop` returns and runs the GNOME session command through the shipped environment contract
  - `dashboard wslg.desktop` launches directly on a normal run and reserves the readable summary for `--dry-run`
  - `dashboard wslg.desktop --size 1024x768` uses the requested dummy mode size
  - both commands now print human-readable summaries instead of raw JSON payloads
  - `dashboard wslg.setup --dry-run --skip-snap-store` returns the Ubuntu `20.04` plan without applying system changes
  - the non-dry-run setup path now writes `wslg-fix.service` before `systemctl enable wslg-fix.service`
  - non-Ubuntu distros are rejected
  - non-WSL hosts are rejected
  - unsupported Ubuntu versions are rejected
  - missing `--ubuntu-version` values are rejected
  - env-based WSL detection through `WSL_DISTRO_NAME` is supported
  - the default temp-file installer path removes its temporary file after use
- Coverage artifact cleanup passed:
  - `cover_db` was removed after verification with a disposable Docker cleanup container
- Real host verification passed on `claudev1`:
  - host: Ubuntu `24.04.4` on WSL2 kernel `6.6.114.1-microsoft-standard-WSL2`
  - `dashboard wslg.desktop --dry-run` returned the GNOME session command successfully
  - `dashboard skills install wslg` updated the host from `0.04` to `0.06`
  - `dashboard wslg.desktop --dry-run --size 1024x768` returned the requested dummy mode size successfully
  - `dashboard wslg.setup` completed successfully after the `0.03` enable-order fix
  - the prior live-host failure was reproduced before the fix as `Failed to enable unit: Unit file wslg-fix.service does not exist.`
  - the desktop launcher no longer depends on `/bin/sh -lc`, so the host-side shell syntax error path is removed
