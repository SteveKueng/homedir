export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# Save Vorssaint settings to iCloud (other private config is symlinked there already).
homedir-save() {
  /Applications/Vorssaint.app/Contents/MacOS/Vorssaint --export-settings \
    "$HOME/Library/Mobile Documents/com~apple~CloudDocs/homedir/vorssaint.plist"
}

# Remind about uncommitted / unpushed changes in the homedir repo.
() {
  local d="$HOME/Git/homedir" n u
  [ -d "$d/.git" ] || return
  n=$(git -C "$d" status --porcelain | wc -l | tr -d ' ')
  u=$(git -C "$d" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
  (( n + u )) && echo "homedir: $n uncommitted, $u unpushed  →  cd ~/Git/homedir"
  # An atomic rewrite by Claude would silently replace the iCloud symlink.
  [ -e "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ] \
    && echo "homedir: ~/.claude/settings.json is no longer linked to iCloud — re-run setup.sh"
  return 0
}

# Machine-local config (PATHs for go/.NET/flutter, secrets…). Not committed.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
