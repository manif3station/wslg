# wslg

## Description

`wslg` is a Developer Dashboard skill that automates the Ubuntu-on-WSLg GNOME desktop bootstrap needed to run a full nested GNOME shell inside WSLg.

## Value

It turns a long, error-prone WSLg guide into one repeatable command that can validate the environment, choose the right Ubuntu-specific file paths, and apply the required systemd configuration consistently.

## Problem It Solves

Running a full GNOME desktop shell inside WSLg needs more than a plain `wsl --install`. The host must already have WSLg, the Ubuntu package set differs slightly by release, `gdm.service` must stay masked, `/tmp/.X11-unix` needs a WSLg-specific fixup unit, and the GNOME nested override path changes between Ubuntu `20.04` and Ubuntu `22.04` or `24.04`.

## What It Does To Solve It

This skill:

- validates that the command is running inside WSL on Ubuntu
- supports Ubuntu `20.04`, `22.04`, and `24.04`
- runs the package update and desktop package install flow
- optionally installs `snap-store`
- masks `gdm.service`
- writes `/etc/systemd/system/wslg-fix.service` with the correct release-specific contents
- writes the correct nested GNOME override file for the detected Ubuntu release
- reloads systemd, enables the `wslg-fix.service` unit, and restarts it so the X11 fix applies immediately
- prints the required final `wsl.exe --shutdown` and `gnome-session` follow-up steps
- supports `--dry-run` so the full generated plan can be reviewed without changing the system

## Developer Dashboard Feature Added

This skill adds:

- `dashboard wslg.setup`
- `dashboard wslg.desktop`

## Installation

Install from the skill repository:

```bash
dashboard skills install git@github.mf:manif3station/wslg.git
```

Install by skill name:

```bash
dashboard skills install wslg
```

## How To Use It

Apply the setup on a supported Ubuntu WSL distro:

```bash
dashboard wslg.setup
```

Review the generated plan without changing the system:

```bash
dashboard wslg.setup --dry-run
```

Skip the optional Snap Store install:

```bash
dashboard wslg.setup --skip-snap-store
```

Force the Ubuntu version when you want to review a specific plan shape:

```bash
dashboard wslg.setup --dry-run --ubuntu-version 24.04
```

After setup completes, shut WSL down from Windows and then start GNOME again inside the distro:

```bash
wsl.exe --shutdown
```

Then start the desktop session through the skill:

```bash
dashboard wslg.desktop
```

That command is meant to launch the desktop directly. It does not print a summary first on a normal run.

Start the desktop session with a specific window size:

```bash
dashboard wslg.desktop --size 1024x768
```

Preview the exact desktop command without launching GNOME:

```bash
dashboard wslg.desktop --dry-run
```

The dry-run output is now shown as `export ...` lines followed by `gnome-session --session=ubuntu`, so it can be pasted back into the shell safely.

```bash
DESKTOP_SESSION=ubuntu \
GDMSESSION=ubuntu \
GNOME_SHELL_SESSION_MODE=ubuntu \
GTK_IM_MODULE=ibus \
GTK_MODULES=gail:atk-bridge \
IM_CONFIG_CHECK_ENV=1 \
IM_CONFIG_PHASE=1 \
QT_ACCESSIBILITY=1 \
QT_IM_MODULE=ibus \
XDG_CURRENT_DESKTOP=ubuntu:GNOME \
XDG_DATA_DIRS=/usr/share/ubuntu:$XDG_DATA_DIRS \
XDG_SESSION_TYPE=wayland \
XMODIFIERS=@im=ibus \
MUTTER_DEBUG_DUMMY_MODE_SPECS=1366x768 \
gnome-session --session=ubuntu
```

## Practical Examples

Normal case:

```bash
dashboard wslg.setup
```

Start the desktop session after setup:

```bash
dashboard wslg.desktop
```

Start the desktop session at `1024x768`:

```bash
dashboard wslg.desktop --size 1024x768
```

Edge case when you only want to inspect what Ubuntu `20.04` would do:

```bash
dashboard wslg.setup --dry-run --ubuntu-version 20.04
```

Edge case when Snap Store is not wanted:

```bash
dashboard wslg.setup --skip-snap-store
```

## WSLg Requirement

This skill does not install WSL itself. The machine must already have a working WSLg installation. The current Microsoft WSLg guidance says fresh installs can use `wsl --install -d Ubuntu`, while existing WSL installs can use `wsl --update` so WSLg is available.

## Provenance

The shipped setup flow is based on the Ubuntu WSLg GNOME guide from the referenced gist, adapted into a non-interactive DD command with a `--dry-run` review mode and explicit release-specific file generation.

## License

`wslg` is released under the MIT License.

See [LICENSE](LICENSE).
