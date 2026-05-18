# Usage

## Prerequisite

Run this skill only after WSLg itself already works on the Windows host. Microsoft currently documents fresh WSLg installs through `wsl --install -d Ubuntu` and updates to existing WSL installs through `wsl --update`.

## Main Command

```bash
dashboard wslg.setup
```

## Start The Desktop Session

```bash
dashboard wslg.desktop
```

`dashboard wslg.desktop` launches GNOME directly and does not print the summary first.

## Start The Desktop Session At A Specific Size

```bash
dashboard wslg.desktop --size 1024x768
```

## Preview The Desktop Command

```bash
dashboard wslg.desktop --dry-run
```

The dry-run output uses `export` lines so the preview can be pasted back into the shell safely.

## Dry Run

Review the generated commands and file contents without changing the system:

```bash
dashboard wslg.setup --dry-run
```

## Skip Snap Store

Skip the optional store package:

```bash
dashboard wslg.setup --skip-snap-store
```

## Force A Specific Ubuntu Version

```bash
dashboard wslg.setup --dry-run --ubuntu-version 24.04
```

## Follow-Up After Setup

Shut WSL down from Windows:

```bash
wsl.exe --shutdown
```

Then reopen the distro and start GNOME through the skill:

```bash
dashboard wslg.desktop
```

The desktop command runs this GNOME startup environment:

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
gnome-session
```
