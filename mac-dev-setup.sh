#!/usr/bin/env bash
# Mac terminal environment setup script.

set -euo pipefail

# Report the location of any unexpected failure.
trap 'echo "❌ Setup failed (line $LINENO)" >&2' ERR

# Keep the Mac awake while the script runs (installs can take a while).
if [ -z "${MAC_DEV_SETUP_CAFFEINATED:-}" ] && command -v caffeinate >/dev/null 2>&1; then
  export MAC_DEV_SETUP_CAFFEINATED=1
  exec caffeinate -i "$0" "$@"
fi

echo "🚀 Starting Mac terminal package installation..."

# Add a line to a file only if it is not already present.
append_if_missing() {
  local line="$1"
  local file="$2"

  touch "$file"

  if ! grep -qxF "$line" "$file"; then
    printf '%s\n' "$line" >> "$file"
  fi
}

# Install a single Homebrew formula/cask, tolerating individual failures.
brew_install() {
  local kind="$1"
  shift

  local pkg
  for pkg in "$@"; do
    if [ "$kind" = "cask" ]; then
      brew install --cask "$pkg" || echo "⚠️  Failed to install cask $pkg, continuing." >&2
    else
      brew install "$pkg" || echo "⚠️  Failed to install $pkg, continuing." >&2
    fi
  done
}

# Ensure Xcode Command Line Tools are installed.
# Git and several development tools depend on them.
if ! xcode-select -p >/dev/null 2>&1; then
  echo "📐 Xcode Command Line Tools are required."
  xcode-select --install
  echo "Complete the installation, then run this script again."
  exit 0
fi

# Install Homebrew only if it is not already installed.
if ! command -v brew >/dev/null 2>&1; then
  echo "📦 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Locate Homebrew based on CPU architecture.
if [ -x /opt/homebrew/bin/brew ]; then
  # Apple Silicon
  BREW_BIN=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
  # Intel Mac
  BREW_BIN=/usr/local/bin/brew
else
  echo "Homebrew could not be found." >&2
  exit 1
fi

# Enable Homebrew in the current script.
eval "$("$BREW_BIN" shellenv)"

# Enable Homebrew automatically in future shell sessions.
# .zprofile covers login shells; that is enough for Zsh on macOS.
BREW_SHELLENV="eval \"\$($BREW_BIN shellenv)\""
append_if_missing "$BREW_SHELLENV" "$HOME/.zprofile"

# Update Homebrew package information.
echo "🔄 Updating Homebrew..."
brew update

# Install terminal application and fonts.
echo "👻 Installing Ghostty and fonts..."
brew_install cask \
  ghostty \
  font-d2coding-nerd-font

# Install command-line tools.
echo "🛠️ Installing CLI tools..."
brew_install formula \
  lsd \
  bat \
  fzf \
  fd \
  ripgrep \
  git-delta \
  btop \
  dust \
  duf \
  fastfetch \
  neovim \
  zoxide \
  lazygit \
  navi \
  starship \
  mise \
  gemini-cli

# Configure global Git defaults.
echo "🔧 Configuring Git..."
git config --global user.name "danielkim"
git config --global user.email "danielkim@shortchall.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true
if command -v delta >/dev/null 2>&1; then
  git config --global core.pager delta
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
  git config --global merge.conflictStyle zdiff3
fi

# Install Zinit only if it is not already installed.
if [ ! -d "$HOME/.local/share/zinit/zinit.git" ]; then
  echo "🔌 Installing Zinit..."

  mkdir -p "$HOME/.local/share/zinit"

  git clone https://github.com/zdharma-continuum/zinit.git \
    "$HOME/.local/share/zinit/zinit.git"
fi

# Install SCM Breeze only if it is not already installed.
if [ ! -d "$HOME/.scm_breeze" ]; then
  echo "🌿 Installing SCM Breeze..."

  git clone https://github.com/scmbreeze/scm_breeze.git \
    "$HOME/.scm_breeze"

  "$HOME/.scm_breeze/install.sh"
fi

# Enable mise for this Bash process.
eval "$(mise activate bash)"

# Install and select Node.js 24 as the default global version.
echo "📐 Installing Node.js through mise..."
mise use --global node@24

# Wire the installed tools into future Zsh sessions.
echo "📝 Configuring .zshrc..."
# Use Neovim as the default editor (edit-command-line, git, etc.).
append_if_missing 'export EDITOR=nvim' "$HOME/.zshrc"
append_if_missing 'export VISUAL=nvim' "$HOME/.zshrc"
append_if_missing 'eval "$(mise activate zsh)"' "$HOME/.zshrc"
append_if_missing 'eval "$(zoxide init zsh)"' "$HOME/.zshrc"
append_if_missing 'eval "$(starship init zsh)"' "$HOME/.zshrc"
append_if_missing 'source <(fzf --zsh)' "$HOME/.zshrc"
append_if_missing 'source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"' "$HOME/.zshrc"
append_if_missing 'zinit light zsh-users/zsh-autosuggestions' "$HOME/.zshrc"
append_if_missing 'zinit light zsh-users/zsh-completions' "$HOME/.zshrc"
# Initialize the completion system (provides compdef) after fpath is populated.
append_if_missing 'autoload -Uz compinit && compinit' "$HOME/.zshrc"
append_if_missing '[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"' "$HOME/.zshrc"
# zsh-syntax-highlighting must load after every other plugin that touches ZLE.
append_if_missing 'zinit light zsh-users/zsh-syntax-highlighting' "$HOME/.zshrc"
# Edit the current command line in $EDITOR with Ctrl-X Ctrl-E.
append_if_missing 'autoload -Uz edit-command-line && zle -N edit-command-line' "$HOME/.zshrc"
append_if_missing "bindkey '^X^E' edit-command-line" "$HOME/.zshrc"
# Pattern-based batch file renaming: zmv '(*).txt' '$1.md'
append_if_missing 'autoload -Uz zmv' "$HOME/.zshrc"

# Aliases for the modern CLI replacements.
# Only safe drop-ins / new names; tools with incompatible flags
# (du→dust, df→duf, grep→rg) are left alone.
append_if_missing "alias ls='lsd --group-dirs first'" "$HOME/.zshrc"
append_if_missing "alias ll='lsd -l --group-dirs first'" "$HOME/.zshrc"
append_if_missing "alias la='lsd -la --group-dirs first'" "$HOME/.zshrc"
append_if_missing "alias lt='lsd --tree'" "$HOME/.zshrc"
append_if_missing "alias cat='bat --paging=never'" "$HOME/.zshrc"
append_if_missing "alias vim='nvim'" "$HOME/.zshrc"
append_if_missing "alias vi='nvim'" "$HOME/.zshrc"
append_if_missing "alias lg='lazygit'" "$HOME/.zshrc"

# Install Claude Code only if it is not already available.
if ! command -v claude >/dev/null 2>&1; then
  echo "🤖 Installing Claude Code..."
  npm install --global \
  --allow-scripts=@anthropic-ai/claude-code \
  @anthropic-ai/claude-code
fi

# Install Codex CLI only if it is not already available.
if ! command -v codex >/dev/null 2>&1; then
  echo "🤖 Installing Codex CLI..."
  npm install --global @openai/codex
fi

# Remove stale Homebrew downloads and old versions.
echo "🧹 Cleaning up Homebrew..."
brew cleanup

# Print installed tool versions.
echo
echo "✅ Base package installation is complete!"
echo
echo "Installed versions:"
brew --version
node --version
npm --version
claude --version || true
codex --version || true
gemini --version || true
