# 2026-05-18 Service Enable Order Fix

- bumped the skill version to `0.03`
- fixed `dashboard wslg.setup` so it writes `/etc/systemd/system/wslg-fix.service` before running `systemctl enable wslg-fix.service`
- reproduced the old failure on the real `claudev1` Ubuntu `24.04` WSL2 host and aligned the setup order to that result
