#!/usr/bin/env bash
# bootstrap-osint: set up an OSINT toolchain and shell environment on Kali
# Linux under WSL.
#
# Usage: bootstrap-osint.sh [--cleanup]
#   --cleanup  offer to remove existing virtualenvs and tools before setup

set -euo pipefail
IFS=$'\n\t'

readonly TOOLS_DIR="$HOME/osint-tools"
readonly VENVS_DIR="$HOME/.venvs"
readonly OSINT_VENV="$VENVS_DIR/osint"
readonly SHERLOCK_VENV="$VENVS_DIR/sherlock"

log_info() { echo -e "[\033[34mINFO\033[0m] $*"; }
log_success() { echo -e "[\033[32m OK \033[0m] $*"; }
log_error() { echo -e "[\033[31mERR \033[0m] $*" >&2; }

check_dependencies() {
	local cmd
	for cmd in curl wget git python3 pip3; do
		if ! command -v "$cmd" &>/dev/null; then
			log_error "Missing dependency: $cmd"
			exit 1
		fi
	done
}

install_packages() {
	log_info "Installing system packages..."
	sudo apt update
	sudo apt install -y \
		unzip jq gnupg lsb-release software-properties-common \
		python3-venv build-essential libffi-dev libssl-dev \
		shellcheck bats ripgrep fd-find tmux neovim tree \
		zsh fzf bat yt-dlp eza direnv exifprobe
	log_success "System packages installed."
}

# Appends a line to ~/.bashrc unless that exact line is already there
add_line_once() {
	grep -qxF -- "$1" "$HOME/.bashrc" 2>/dev/null || echo "$1" >>"$HOME/.bashrc"
}

clone_repo() {
	local name=$1 url=$2
	if [[ -d $TOOLS_DIR/$name ]]; then
		log_info "$name already cloned."
	else
		log_info "Cloning $name..."
		git clone "$url" "$TOOLS_DIR/$name"
	fi
}

create_venv() {
	python3 -m venv "$1"
	# shellcheck source=/dev/null
	source "$1/bin/activate"
	pip install --upgrade pip
}

install_python_tools() {
	log_info "Installing Python OSINT tools into $OSINT_VENV..."
	mkdir -p "$VENVS_DIR"
	create_venv "$OSINT_VENV"
	pip install osrframework photon instaloader h8mail shodan
	deactivate
	# shellcheck disable=SC2016 # expanded when .bashrc runs
	add_line_once 'source "$HOME/.venvs/osint/bin/activate"'
	log_success "Python OSINT tools installed."
}

install_git_tools() {
	local pip="$OSINT_VENV/bin/pip"
	mkdir -p "$TOOLS_DIR"

	clone_repo DumpsterDiver https://github.com/securing/DumpsterDiver.git
	"$pip" install requests PyYAML

	clone_repo twayback https://github.com/humandecoded/twayback.git
	"$pip" install -r "$TOOLS_DIR/twayback/requirements.txt"

	clone_repo Sublist3r https://github.com/aboul3la/Sublist3r.git
	"$pip" install -r "$TOOLS_DIR/Sublist3r/requirements.txt"

	clone_repo PhoneInfoga https://github.com/sundowndev/PhoneInfoga.git
	log_success "Git-based tools installed."
}

# Sherlock gets its own virtualenv, as its dependencies clash with the others
install_sherlock() {
	local sherlock_dir="$TOOLS_DIR/sherlock"
	clone_repo sherlock https://github.com/sherlock-project/sherlock.git

	log_info "Installing Sherlock into $SHERLOCK_VENV..."
	create_venv "$SHERLOCK_VENV"
	if [[ -f $sherlock_dir/requirements/base.txt ]]; then
		pip install -r "$sherlock_dir/requirements/base.txt"
	elif [[ -f $sherlock_dir/requirements.txt ]]; then
		pip install -r "$sherlock_dir/requirements.txt"
	else
		pip install "$sherlock_dir"
	fi
	deactivate
	log_success "Sherlock installed. Activate with: source ~/.venvs/sherlock/bin/activate"
}

configure_env() {
	log_info "Configuring shell environment..."
	# shellcheck disable=SC2016 # expanded when .bashrc runs
	add_line_once 'eval "$(direnv hook bash)"'
	add_line_once 'source /usr/share/doc/fzf/examples/key-bindings.bash'
	add_line_once 'alias bat=batcat'
	add_line_once 'alias exa=eza'
	add_line_once 'alias youtube-dl=yt-dlp'
	log_success "Environment configured. Restart your shell to apply it."
}

confirm_remove() {
	local path=$1 label=$2 answer
	if [[ ! -d $path ]]; then
		echo "No $label found at $path."
		return
	fi
	read -rp "Remove $label at $path? [y/N] " answer
	if [[ $answer =~ ^[Yy]$ ]]; then
		rm -rf -- "$path"
		echo "Removed $label."
	else
		echo "Kept $label."
	fi
}

cleanup() {
	confirm_remove "$OSINT_VENV" "OSINT virtualenv"
	confirm_remove "$SHERLOCK_VENV" "Sherlock virtualenv"
	confirm_remove "$TOOLS_DIR" "OSINT tools directory"
}

main() {
	case ${1:-} in
	--cleanup) cleanup ;;
	'') ;;
	*)
		log_error "Unknown option: $1 (usage: $(basename "$0") [--cleanup])"
		exit 1
		;;
	esac

	check_dependencies
	install_packages
	install_python_tools
	install_git_tools
	install_sherlock
	configure_env
	log_success "OSINT environment setup complete."
}

main "$@"
