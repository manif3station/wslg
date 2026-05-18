# SOW

## SOW-001

Create a `wslg` DD skill that can apply the Ubuntu WSLg nested GNOME desktop bootstrap from a single `dashboard wslg.setup` command, with Docker-tested verification and an explicit MIT license.

## Scope

- implement `dashboard wslg.setup`
- support Ubuntu `20.04`, `22.04`, and `24.04`
- validate WSL and Ubuntu before applying system changes
- write the WSLg fix service and nested GNOME override files
- expose a `--dry-run` mode for plan review
- verify the skill inside Docker
- document usage, examples, and follow-up steps
- add an explicit MIT license and README license documentation
- complete documentation, commit, and push gates
