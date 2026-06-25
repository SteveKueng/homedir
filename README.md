# homedir — machine as code

My Mac setup as code: dotfiles, Homebrew, Claude Code config. One script to set up
a fresh Mac, one to back the live config into the repo.

## New Mac — one-liner

```sh
curl -fsSL https://raw.githubusercontent.com/SteveKueng/homedir/main/bootstrap.sh | bash
```

With macOS tweaks: append `-s -- --defaults` → `… | bash -s -- --defaults`.

`bootstrap.sh` ensures git is present, clones this repo to `~/Git/homedir` (or pulls
if already there), then runs `setup.sh`. Requires the repo to be **public** so the
raw URL is reachable without auth — that's fine here, no secrets are committed.

> Clones over HTTPS (a fresh Mac has no SSH key yet). After setup, `.gitconfig`'s
> `insteadOf` rewrite makes pushes go over SSH automatically.

`setup.sh` is idempotent. It:
1. installs Homebrew + oh-my-zsh if missing,
2. `brew bundle` (CLI tools, casks, VSCode extensions from `Brewfile`),
3. symlinks `home/*` dotfiles into `$HOME` (existing files → `*.pre-homedir.bak`),
4. copies the portable `claude/settings.json` to `~/.claude/`,
5. optionally applies `macos/defaults.sh`.

Open a new terminal afterwards.

## Backup (capture current config → repo)

```sh
./backup.sh        # updates Brewfile + claude settings, commits (no push)
git push           # when you're ready
```

Dotfiles are symlinked, so editing e.g. `~/.zshrc` already changes the repo file —
`backup.sh` mainly refreshes the `Brewfile` and re-sanitizes `claude/settings.json`
(strips username + plugin version from the statusLine path).

## Manual steps (not automated)

- **App logins** — sign into apps (browsers, 1Password, etc.).
- **App Store apps** — `mas` isn't used. Install from the App Store, or `brew install mas`,
  add `mas "App", id: 12345` lines to the `Brewfile`, then they're covered.
- **SSH keys** — generate (`ssh-keygen -t ed25519`) and add to GitHub. Keys are never
  committed.
- **`~/.zshrc.local`** — machine-local / secret shell config goes here. Gitignored,
  auto-sourced by `.zshrc` if present.

## Secrets

Nothing secret is committed in cleartext (`.gitignore` blocks `.env`, `*.key`, `*.pem`,
`~/.zshrc.local`). For secrets you *do* want versioned, encrypt with `age` or `sops`
(both already in the `Brewfile`) and commit only the ciphertext.

## Portability

No hardcoded `/Users/<name>` paths — dotfiles use `$HOME`, and the Claude statusLine
path is globbed (`.../ponytail/*/hooks/...`) so username and plugin version don't matter.
