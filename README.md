# homedir

My Mac setup as code. One command sets up a fresh Mac:

```sh
curl -fsSL https://ikueng.ch/install | bash
```

(Opening [ikueng.ch/install](https://ikueng.ch/install) in a browser shows the same command.)
Apple Silicon only. Asks for your password once.

## What it does

`bootstrap.sh` installs the Xcode Command Line Tools if needed, clones this repo to
`~/Git/homedir`, then runs `setup.sh`, which:

1. asks for the computer name,
2. waits until you're signed in to your Apple Account with iCloud Drive on,
3. installs Homebrew, oh-my-zsh and everything in the `Brewfile`,
4. symlinks the dotfiles in `home/` into `$HOME`,
5. symlinks private config from iCloud Drive (`homedir/` folder): kubeconfig, Claude settings,
6. imports Vorssaint settings from iCloud (first run only),
7. logs in to GitHub in the browser, creates an SSH key named after the computer and uploads it,
8. turns on Touch ID for `sudo` and the firewall, warns if FileVault is off,
9. applies `macos/defaults.sh` (Finder, Dock, keyboard, trackpad, screenshot shortcuts off),
10. sets up the Dock apps (first run only),
11. opens the privacy settings for Vorssaint's permissions.

Re-running is safe. Flags: `--no-defaults` skips macOS defaults, `--force` redoes the
first-run-only steps.

## Where things live

- **This repo (public):** scripts and anything that isn't secret.
- **iCloud Drive `homedir/` (private, end-to-end encrypted with Advanced Data Protection):**
  `kube/config`, `claude/settings.json`, `vorssaint.plist`.
- **`~/.zshrc.local`, `~/.ssh/config.local`:** per-machine config, never committed.

## Day to day

- **Add an app:** add a line to the `Brewfile`, run `./setup.sh`.
- **Change a macOS setting for every Mac:** add a `defaults write` line to `macos/defaults.sh`.
- **Changed Vorssaint settings:** run `homedir-save`.
- **Dotfiles** are symlinks, so edits land in the repo. New terminals show
  `homedir: N uncommitted` until you commit and push.

## Manual steps

- Grant Vorssaint Accessibility and Screen Recording (setup opens the pages).
- Sign in to the App Store, then re-run setup for Xcode.
- Log out once so keyboard shortcut changes take effect.
- Delete SSH keys of old Macs at <https://github.com/settings/keys>.

## Shortlink

`web/.htaccess` and `web/install.html` go on the ikueng.ch web server (public and internal).
curl gets redirected to `bootstrap.sh` on GitHub, browsers get the page.
