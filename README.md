# bootstrap-osint

![Bash](https://img.shields.io/badge/Bash-5-4eaa25?logo=gnubash&logoColor=white)
![Kali Linux](https://img.shields.io/badge/Kali_Linux-WSL-557c94?logo=kalilinux&logoColor=white)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

One script that sets up an OSINT toolchain and a comfortable shell on Kali
Linux under WSL. It is safe to run again: existing clones are kept and
`.bashrc` lines are only added once.

## What it sets up

- **System packages:** ripgrep, fd, fzf, bat, eza, jq, tmux, neovim, direnv,
  yt-dlp, exifprobe, shellcheck and bats, plus Python build dependencies.
- **Python tools** in `~/.venvs/osint`: osrframework, photon, instaloader,
  h8mail and shodan.
- **Tools from GitHub** in `~/osint-tools`: DumpsterDiver, Twayback,
  Sublist3r and PhoneInfoga, with their Python dependencies.
- **Sherlock** in its own virtualenv (`~/.venvs/sherlock`), as its
  dependencies clash with the others.
- **Shell:** fzf key bindings, the direnv hook, `bat`/`exa`/`youtube-dl`
  aliases, and the OSINT virtualenv activated in every new shell.

`--cleanup` to remove the virtualenvs and tools folder first, for a
fresh install. Needs `sudo` for the apt packages.

## License

MIT, see [LICENSE](LICENSE).
