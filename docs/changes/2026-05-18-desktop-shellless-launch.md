# 2026-05-18 Desktop Shellless Launch

- bumped the skill version to `0.05`
- changed `dashboard wslg.desktop` to launch through a direct `env ... gnome-session` argv path
- removed the dependency on `/bin/sh -lc` for the desktop command so shell parsing does not break on host-specific environment values
