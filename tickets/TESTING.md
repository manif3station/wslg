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

- Docker functional tests passed: `Files=4, Tests=89`
- Docker coverage passed for `lib/WSLg/Setup.pm`:
  - `100.0%` statement coverage
  - `100.0%` subroutine coverage
- Proven behaviors:
  - `dashboard wslg.setup` applies the Ubuntu `24.04` command plan, service file, and GNOME override path
  - `dashboard wslg.desktop` returns and runs the GNOME session command through the shipped environment contract
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
