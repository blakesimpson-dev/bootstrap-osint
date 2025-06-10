# bootstrap-osint.sh

## Overview
This script bootstraps an OSINT and Bash scripting environment tailored for Kali Linux running on WSL (Windows Subsystem for Linux). It automates installing essential system packages, setting up Python virtual environments, cloning popular OSINT tools from GitHub, and configuring the shell environment with useful aliases and hooks.

## Use Case
Intended for technical users and researchers who want a ready-made OSINT toolchain on Kali Linux under WSL, the script handles installation and environment setup seamlessly.

## Usage
- Run `./bootstrap-osint.sh` for a full installation.
- Run `./bootstrap-osint.sh --cleanup` to prompt for removal of existing virtual environments and OSINT tools before reinstalling.

## Installation Details
The script performs the following tasks:
- Checks for essential dependencies (curl, wget, git, python3, pip3).
- Installs required system packages including Python dev libraries, shell utilities (ripgrep, fzf, bat, etc.), and common tools.
- Creates Python virtual environments to isolate tool installations.
- Installs Python OSINT tools such as `osrframework`, `photon`, `instaloader`, `h8mail`, and `shodan`.
- Clones and sets up popular OSINT repositories like Sherlock, DumpsterDiver, Sublist3r, Twayback, and PhoneInfoga.
- Configures the shell environment by adding aliases and hooks for tools like `fzf`, `direnv`, `batcat`, and others.

## Installed Items
### System Packages
- unzip, jq, gnupg, lsb-release, software-properties-common
- python3-venv, build-essential, libffi-dev, libssl-dev
- shellcheck, bats, ripgrep, fd-find, tmux, neovim, tree
- zsh, fzf, bat, yt-dlp, eza, direnv, exifprobe

### Python Tools (main virtualenv)
- osrframework
- photon
- instaloader
- h8mail
- shodan

### Additional GitHub Tools
- Sherlock
- DumpsterDiver
- Twayback
- Sublist3r
- PhoneInfoga

## Notes
- The script modifies your `.bashrc` to enable automatic activation of the OSINT Python virtual environment.
- Requires sudo privileges for package installation.
- Designed specifically for Kali Linux under WSL, but can be adapted for similar Debian-based environments.

## License
MIT License (see LICENSE file)

## Version
1.0.5
