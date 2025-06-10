# ----------------------------------------------------------------------------
#  bootstrap-osint.sh
#  Bootstrap script to set up OSINT and Bash scripting tools in WSL Kali
#
#  Author: Blake Simpson
#  License: MIT
#  Version: 1.0.5
#  Usage:
#    ./bootstrap-osint.sh            # Perform full setup
#    ./bootstrap-osint.sh --cleanup  # Prompt and clean existing venvs and 
#                                      tools before setup
# ----------------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# ----------------------------------------------------------------------------
# log_info(): Print info messages to stdout
# Globals: none
# Arguments: message string
# Outputs: writes to stdout
# ----------------------------------------------------------------------------
log_info()    { echo -e "[\e[34mINFO\e[0m] $*" >&1; }

# ----------------------------------------------------------------------------
# log_success(): Print success messages to stdout
# Globals: none
# Arguments: message string
# Outputs: writes to stdout
# ----------------------------------------------------------------------------
log_success() { echo -e "[\e[32m OK \e[0m] $*" >&1; }

# ----------------------------------------------------------------------------
# log_error(): Print error messages to stderr
# Globals: none
# Arguments: message string
# Outputs: writes to stderr
# ----------------------------------------------------------------------------
log_error()   { echo -e "[\e[31mERR \e[0m] $*" >&2; }

# ----------------------------------------------------------------------------
# check_dependencies(): Ensure required tools are installed
# Globals: none
# Arguments: none
# Outputs: logs missing dependencies
# ----------------------------------------------------------------------------
check_dependencies() {
  local deps=(curl wget git python3 pip3)
  for cmd in "${deps[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      log_error "Missing dependency: $cmd"
      exit 1
    fi
  done
}

# ----------------------------------------------------------------------------
# install_packages(): Install system packages using apt
# Globals: none
# Arguments: none
# Outputs: installs packages and logs status
# ----------------------------------------------------------------------------
install_packages() {
  log_info "Installing base packages..."
  sudo apt update
  sudo apt install -y \
    unzip jq gnupg lsb-release software-properties-common \
    python3-venv build-essential libffi-dev libssl-dev \
    shellcheck bats ripgrep fd-find tmux neovim tree \
    zsh fzf bat yt-dlp eza direnv exifprobe
  log_success "System packages installed."
}

# ----------------------------------------------------------------------------
# create_venv(): Create a Python virtualenv and activate it
# Globals: none
# Arguments:
#   $1 - venv directory path
# Outputs: activates the venv in the current shell session
# ----------------------------------------------------------------------------
create_venv() {
  local venv_dir="$1"
  python3 -m venv "$venv_dir"
  # shellcheck source=/dev/null
  source "$venv_dir/bin/activate"
}

# ----------------------------------------------------------------------------
# install_python_tools(): Install Python-based OSINT tools in main virtualenv
# Globals: HOME
# Arguments: none
# Outputs: creates venv, installs pip packages
# ----------------------------------------------------------------------------
install_python_tools() {
  log_info "Creating virtualenv for main OSINT tools..."
  mkdir -p "$HOME/.venvs"
  create_venv "$HOME/.venvs/osint"

  log_info "Installing main Python tools in virtualenv..."
  pip install --upgrade pip
  pip install \
    osrframework \
    photon \
    instaloader \
    h8mail \
    shodan
  log_success "Main Python tools installed in virtualenv."

  echo 'source "$HOME/.venvs/osint/bin/activate"' >> "$HOME/.bashrc"
  log_info "To activate your main OSINT virtualenv now: source ~/.venvs/osint/bin/activate"
  deactivate
}

# ----------------------------------------------------------------------------
# install_sherlock_python_tools(): Install Sherlock with dependencies in separate venv
# Globals: HOME
# Arguments: none
# Outputs: creates venv and installs Sherlock pip deps
# ----------------------------------------------------------------------------
install_sherlock_python_tools() {
  local base_dir="$HOME/osint-tools"
  local sherlock_dir="$base_dir/sherlock"
  local sherlock_venv="$HOME/.venvs/sherlock"

  log_info "Cloning Sherlock repo if missing..."
  if [[ ! -d "$sherlock_dir" ]]; then
    git clone https://github.com/sherlock-project/sherlock.git "$sherlock_dir"
  else
    log_info "Sherlock repo already exists."
  fi

  log_info "Creating Sherlock virtualenv..."
  create_venv "$sherlock_venv"

  log_info "Installing Sherlock Python dependencies..."
  pip install --upgrade pip
  if [[ -f "$sherlock_dir/requirements/base.txt" ]]; then
    pip install -r "$sherlock_dir/requirements/base.txt"
  elif [[ -f "$sherlock_dir/requirements.txt" ]]; then
    pip install -r "$sherlock_dir/requirements.txt"
  else
    pip install "$sherlock_dir"
  fi

  log_success "Sherlock installed in separate virtualenv."
  deactivate
  log_info "To activate Sherlock virtualenv: source ~/.venvs/sherlock/bin/activate"
}

# ----------------------------------------------------------------------------
# install_from_git(): Clone and install tools from GitHub
# Globals: HOME
# Arguments: none
# Outputs: Clones and installs external repos
# ----------------------------------------------------------------------------
install_from_git() {
  local base_dir="$HOME/osint-tools"
  mkdir -p "$base_dir"

  log_info "Cloning and installing DumpsterDiver..."
  if [[ ! -d "$base_dir/DumpsterDiver" ]]; then
    git clone https://github.com/securing/DumpsterDiver.git "$base_dir/DumpsterDiver"
  else
    log_info "DumpsterDiver already exists. Skipping clone."
  fi
  "$HOME/.venvs/osint/bin/pip" install requests PyYAML
  log_success "DumpsterDiver ready to use (no pip install required)."

  log_info "Cloning and installing Twayback..."
  if [[ ! -d "$base_dir/twayback" ]]; then
    git clone https://github.com/humandecoded/twayback.git "$base_dir/twayback"
  else
    log_info "Twayback already exists. Skipping clone."
  fi
  "$HOME/.venvs/osint/bin/pip" install -r "$base_dir/twayback/requirements.txt"

  log_info "Cloning Sherlock repo (no pip install here)..."
  if [[ ! -d "$base_dir/sherlock" ]]; then
    git clone https://github.com/sherlock-project/sherlock.git "$base_dir/sherlock"
  else
    log_info "Sherlock already exists. Skipping clone."
  fi

  log_info "Cloning and installing Sublist3r..."
  if [[ ! -d "$base_dir/Sublist3r" ]]; then
    git clone https://github.com/aboul3la/Sublist3r.git "$base_dir/Sublist3r"
  else
    log_info "Sublist3r already exists. Skipping clone."
  fi
  "$HOME/.venvs/osint/bin/pip" install -r "$base_dir/Sublist3r/requirements.txt"

  log_info "Cloning and preparing PhoneInfoga..."
  if [[ ! -d "$base_dir/PhoneInfoga" ]]; then
    git clone https://github.com/sundowndev/PhoneInfoga.git "$base_dir/PhoneInfoga"
  else
    log_info "PhoneInfoga already exists. Skipping clone."
  fi

  log_success "Git-based tools installed."
}

# ----------------------------------------------------------------------------
# configure_env(): Setup user environment for scripting
# Globals: HOME
# Arguments: none
# Outputs: updates bashrc with useful aliases and env hooks
# ----------------------------------------------------------------------------
configure_env() {
  log_info "Setting up shell environment..."
  grep -q 'fzf' ~/.bashrc || echo 'source /usr/share/doc/fzf/examples/key-bindings.bash' >> ~/.bashrc
  grep -q 'direnv' ~/.bashrc || echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
  grep -q 'batcat' ~/.bashrc || echo 'alias bat=batcat' >> ~/.bashrc
  grep -q 'eza' ~/.bashrc || echo 'alias exa=eza' >> ~/.bashrc
  grep -q 'yt-dlp' ~/.bashrc || echo 'alias youtube-dl=yt-dlp' >> ~/.bashrc
  log_success "Environment configured. Restart shell to apply changes."
}

# ----------------------------------------------------------------------------
# cleanup_osint_env(): Prompt and remove existing OSINT and Sherlock venvs and tools directory
# Globals: HOME
# Arguments: none
# Outputs: Prompts user and deletes directories if confirmed
# ----------------------------------------------------------------------------
cleanup_osint_env() {
  local osint_venv="$HOME/.venvs/osint"
  local sherlock_venv="$HOME/.venvs/sherlock"
  local tools_dir="$HOME/osint-tools"

  if [[ -d $osint_venv ]]; then
    read -rp "Remove existing OSINT virtualenv at $osint_venv? [y/N]: " yn
    if [[ $yn =~ ^[Yy]$ ]]; then
      rm -rf "$osint_venv"
      echo "OSINT virtualenv removed."
    else
      echo "Skipped OSINT virtualenv removal."
    fi
  else
    echo "No OSINT virtualenv found at $osint_venv."
  fi

  if [[ -d $sherlock_venv ]]; then
    read -rp "Remove existing Sherlock virtualenv at $sherlock_venv? [y/N]: " yn
    if [[ $yn =~ ^[Yy]$ ]]; then
      rm -rf "$sherlock_venv"
      echo "Sherlock virtualenv removed."
    else
      echo "Skipped Sherlock virtualenv removal."
    fi
  else
    echo "No Sherlock virtualenv found at $sherlock_venv."
  fi

  if [[ -d $tools_dir ]]; then
    read -rp "Remove existing OSINT tools directory at $tools_dir? [y/N]: " yn
    if [[ $yn =~ ^[Yy]$ ]]; then
      rm -rf "$tools_dir"
      echo "OSINT tools directory removed."
    else
      echo "Skipped OSINT tools removal."
    fi
  else
    echo "No OSINT tools directory found at $tools_dir."
  fi
}


# ----------------------------------------------------------------------------
# main(): Entrypoint to script execution
# Globals: none
# Arguments: CLI args passed to main
# Outputs: orchestrates full setup process
# ----------------------------------------------------------------------------
main() {
  local cleanup_flag=0

  for arg in "$@"; do
    case "$arg" in
      --cleanup) cleanup_flag=1 ;;
      *) ;;
    esac
  done

  if (( cleanup_flag )); then
    cleanup_osint_env
  fi

  check_dependencies
  install_packages
  install_python_tools
  install_from_git
  install_sherlock_python_tools
  configure_env
  log_success "OSINT environment setup complete."
}

main "$@"
