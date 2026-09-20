# NixOS configurations

Flake-based NixOS configurations for a fleet of servers, LXC containers, and workstations, with CI-gated, signature-verified GitOps deployment. Servers track the stable channel (26.05); workstations track unstable. Hosts build as `.#hostname`, except `srv-n3`, whose hostname is still `git`.

My primary private server is **srv-n1**. Its configuration and the security layers behind it are documented at https://codeberg.org/sensei/nixos/wiki/srv-n1

My public server is **srv-n2**. It hosts https://libresearch.space and https://pasted.space, as well as a Matrix homeserver. More information on it's configuration can be found at https://codeberg.org/sensei/nixos/wiki/srv-n2

This configuration is specific to one environment. Hostnames, usernames, disk layouts, mounts, and secrets will not transfer directly. Review every file before reusing any part of it.

## Table of contents

- [Repo structure](#repo-structure)
- [Hosts](#hosts)
- [Modules](#modules)
- [Why Quadlets](#why-quadlets)
- [Deployment pipeline](#deployment-pipeline)
- [Build commands](#build-commands)
- [Showcase](#showcase)
- [Installation](#installation)
- [Sponsor NixOS](#sponsor-nixos)
- [GitHub mirror](#github-mirror)

## Repo structure

- `/.forgejo`: CI workflows. Host builds, deploy gating, and Renovate.
- `/config`: application configuration files (ghostty, niri, waybar, etc.), deployed to `~/.config` through Home Manager.
- `/home`: Home Manager configurations. `common.nix` is the workstation baseline, `server.nix` the server baseline, plus per-environment and per-shell files.
- `/machines`: per-host configuration, grouped into `desktop`, `laptop`, `lxc`, and `server`. Each host directory holds its `default.nix`, `hardware-configuration.nix`, disko layout, and any host-specific services. Server hosts define their OCI containers under `containers/`. Retired hosts are preserved on the `legacy` branch.
- `/modules`: shared NixOS modules, exposed as options under the `workstation.*` and `server.*` namespaces.
- `/pkgs`: package derivations not available in nixpkgs.
- `/secrets`: sops-encrypted secrets. `/.sops.yaml` at the repo root defines which host keys can decrypt each secret.
- `/tofu`: OpenTofu + nixos-anywhere provisioning. `vm.tf` and `lxc.tf` are templates, copied to a throwaway per-host file for the install and deleted afterwards.

## Hosts

`flake.nix` defines two host builders. `mkWorkstation` builds against nixpkgs-unstable with the latest kernel; `mkServer` builds against nixpkgs-stable with an LTS kernel and imports the server baseline (SSH, service defaults, continuous deployment, binary cache, DNS, scheduled reboots). Both wire in Home Manager, disko, and sops-nix.

Current outputs:

| Host           | Type        | Role                                                                   |
| -------------- | ----------- | ---------------------------------------------------------------------- |
| `console`      | workstation | living-room KDE build with controller support                          |
| `srv-n1`       | server      | primary server; runs most services as rootless Quadlets                |
| `srv-n2`       | server      | public-facing edge; Traefik, Anubis, CrowdSec, self-hosted ingress     |
| `srv-n3`       | server      | Forgejo, Pocket ID, and Technitium DNS server (tailnet only)           |
| `pangolin`     | server      | Pangolin tunnel/ingress node                                           |
| `jellyfin`     | LXC         | media server                                                           |
| `runner`       | LXC         | Forgejo Actions runner and Harmonia binary cache                       |
| `second-brain` | LXC         | second-brain service, consumed as a flake input                        |
| `mongoose`     | LXC         | qBittorrent behind WireGuard, ZFS dataset passed through from the host |
| `filebrowser`  | LXC         | FileBrowser Quantum over the nas datasets and scratch disks            |

`erebos` (desktop) and `prometheus` (laptop) are defined but currently commented out, as is a five-node k3s cluster. Anything commented out is not being actively developed or maintained.

## Modules

Modules are enable-gated options rather than unconditional imports. Workstation functionality lives under `workstation.*` (`baseline`, `packages`, desktop environments, `virtualization`, etc.); server functionality lives under `server.*` (`baseline`, `cd`, `cache`, `dns`, `kernelReboot`). A host enables what it needs:

```nix
workstation.baseline.enable = true;
workstation.niri.enable = true;
```

Notes:

- Garbage collection removes generations older than 7 days on workstations and 5 days on servers. Store optimization runs weekly on both.
- The user is created with an `initialPassword`, and SSH is key-only. Set a real password on first boot.
- All builds default to zsh. A bash Home Manager file exists; swap the shell import in `flake.nix`.
- Desktop environments use their stock display managers (GDM, SDDM, LightDM). Window managers use `tuigreet` with autologin. Niri (with Noctalia Shell) is the most actively maintained environment; GNOME, KDE, and XFCE are stable; Hyprland lags upstream.

## Why Quadlets

Services run as rootless Quadlets, not as native services. Nearly all of them have a NixOS module or a community equivalent, and NixOS has abundant container tooling. I stuck with Quadlets because:

- Declarative by nature. A Quadlet unit is a systemd unit; there is no second mechanism to reconcile.
- Documentation & familiarity. OCI containers have extensive documentation between Docker/Podman. It's also what I'm most familiar with.
- Readability. Nix is dense with poor documentation. This can be a problem for someone outside the Nix community. The Quadlet configs are written to be read on their own, so a container definition ports to any environment that runs Podman or Docker.
- Data. Container state is easier to locate, move, and back up than the state of a native service, or of a NixOS container, which is a wrapper around systemd-nspawn.

## Deployment pipeline

Servers are usually not rebuilt by hand.

1. Forgejo Actions builds every flake output on push and pull request (`nix-build.yaml`).
2. Renovate opens PRs for container image and flake input updates. Non-major container updates and lock file maintenance automerge once CI passes. New containers are pinned as `tag@digest`.
3. A daily gate job (`deploy-gate.yaml`) rebuilds all comin-enabled hosts from `main` and force-pushes the result to `deploy-candidate`.
4. A follow-up job (`deploy-release.yaml`) promotes `deploy-candidate` to `deploy`.
5. [comin](https://github.com/nlewo/comin) on each server polls the `deploy` branch, verifies the tip commit is signed by a trusted key (hardware security key or the Forgejo instance signing key, which signs all PR merges), and applies it. Unsigned tips are refused, and `deploy` only ever moves fast-forward.

## Build commands

From the repo root:

```
sudo nixos-rebuild boot --flake .#console
```

The same form applies to any other entry in the flake. Server hosts can be built this way for testing, but routine changes reach them through the deployment pipeline above.

## Showcase

<video src="https://codeberg.org/sensei/nixos/raw/branch/assets/recording_20260208_103359.mp4" controls width="100%"></video>

## Installation

For installation instructions, see https://codeberg.org/sensei/nixos/wiki/Installation-instructions

## Sponsor NixOS

Consider sponsoring NixOS to support the people who make this possible: https://github.com/sponsors/NixOS

## GitHub mirror

https://github.com/nuclear-gumbo/nixos
