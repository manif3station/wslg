# Overview

`wslg` packages the Ubuntu WSLg nested GNOME desktop bootstrap into Developer Dashboard skill commands.

## Scope

The current release focuses on one governed entrypoint:

- `dashboard wslg.setup`
- `dashboard wslg.desktop`

## Supported Ubuntu Releases

- `20.04`
- `22.04`
- `24.04`

## Managed Changes

The setup flow applies the same core sequence described in the referenced WSLg guide:

- update APT metadata
- upgrade installed packages
- optionally install `snap-store`
- install `ubuntu-desktop`, plus `acpi-support-` on Ubuntu `20.04` and `22.04`
- mask `gdm.service`
- write `/etc/systemd/system/wslg-fix.service`
- write the GNOME nested Wayland override file
- enable `wslg-fix.service`

## Non-Goals

- installing WSL itself
- enabling Windows features outside the distro
- auto-running `wsl.exe --shutdown`
- auto-starting GNOME after setup

Those final steps remain explicit user follow-up actions because shutting down WSL from inside the running setup session would terminate the command abruptly.
