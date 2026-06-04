# AGENTS.md — dotfiles

Personal dotfiles managed with **GNU Stow** + Git. Primary: **Arch Linux** + **DWM** (startx, no DM). Also runs on NixOS (`thinkbox`) and Void.

## Structure

Each top-level directory is a Stow package containing `$HOME`-relative paths:

| Package | What |
|---------|------|
| `shell/` | profile, aliasrc, shortcutrc, inputrc |
| `zsh/` | .zshrc (Luke's Zoomer Shell), vi mode |
| `nvim/` | init.lua (modularized with neovide.lua), lua/{core,plugins,utils}/ — fully tracked |
| `tmux/` | prefix Ctrl+Space, vi nav, escape-time 0 |
| `x11/` | xinitrc (D-Bus → DWM), xprofile, xresources |
| `scripts/` | `~/.local/bin` — compiled suckless tools (dwm, st, dmenu, dwmblocks) + all scripts |
| `nixos/` | flake.nix, hosts/thinkbox/, home/home.nix |
| `lf/` | lf file manager (vi binds, ueberzug preview, interactive extract/compress, README guide via Ecfh) |
| `media/` | mpv, ncmpcpp, mpd configs |
| `opencode/` | 9Router gateway config, 3 combo tiers (KhaBoDo, KhaSimple, KhaThinking) |

## Key commands / workflow

- **Deploy:** `stow -vt ~ <package>` (repeat for each package)
- **Undeploy:** `stow -Dvt ~ <package>`
- **Session start:** auto via `shell/.zprofile` — when on tty1, runs `startx "$XINITRC"` → `xinitrc` → `exec ssh-agent dwm`
- **X11:** `xinitrc` handles display/autostart apps, and sources `xinitrc.$OS` for OS-specific audio setups (Pipewire, etc.)
- **Shortcuts:** `shortcuts` regenerates `shortcutrc`/`shortcutenvrc`/`zshnameddirrc` from `bm-dirs`/`bm-files`
- **Git Manager:** `gm` — multi-account git tool under `~/Repos/`, uses git `includeIf`
- **Wallpapers:** `setbg` — handles WebP, pywal, xwallpaper; runs at X startup
- **Cron:** `cron/crontog` toggles all cron jobs; `cron/checkup` (pacman), `cron/newsup` (RSS)

## Environment

- `EDITOR=nvim`, `TERMINAL=st`, `BROWSER=brave`
- `SUDO_ASKPASS=$HOME/.local/bin/dmenupass`
- Full XDG dirs set in `shell/.config/shell/profile`
- `ZDOTDIR=$XDG_CONFIG_HOME/zsh`
- vi mode in: zsh, tmux, lf, ncmpcpp, mpv

## Stow quirks

- `scripts/.local/bin/cron/` subdirectory has actual files; `checkup`/`crontog`/`newsup` are symlinks to `cron/*` so they're in PATH + cron jobs can use absolute paths
- `scripts/.local/bin/user/` has bluetooth scripts (`btmgr`, `btpair`, `btclean`, etc.) — kept separate to avoid cluttering the flat namespace
- `.stow-local-ignore` used in `app_desktop/`
- `.gitignore` only ignores `.zcompdump*` and `shell/.config/shell/profile.local` (used for 9Router API keys)

## NixOS

- `nixos/flake.nix` → `nixosConfigurations.thinkbox` (x86_64-linux, systemd-boot, state 24.11)
- Home-manager with `backupFileExtension = "backup"`
- `home-manager.extraSpecialArgs.dotfiles` points to `/home/ka/.dotfiles`
