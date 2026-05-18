# 2026-05-18 WSLg Fix Restart And XDG Fallback

- bumped the skill version to `0.09`
- changed `wslg.setup` to reload systemd and restart `wslg-fix.service` immediately after writing the unit files
- changed `wslg.desktop` to use a fallback `XDG_DATA_DIRS` when the inherited shell environment is empty
