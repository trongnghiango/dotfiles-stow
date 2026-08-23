# AGENTS.md — dotfiles

Personal dotfiles managed with **GNU Stow** + Git. Primary: **Arch Linux + Omarchy (Hyprland / Wayland)**. Also supports NixOS (`thinkbox`).

## Structure

Each top-level directory is a Stow package containing `$HOME`-relative paths:

| Package | What |
|---------|------|
| `shell/` | profile, aliasrc, shortcutrc, inputrc, bm-dirs, bm-files |
| `zsh/` | .zshrc (Luke's Zoomer Shell), vi mode, env.zsh |
| `nvim/` | init.lua (modularized), lua/{core,plugins,utils}/ — fully tracked and aligned with Omarchy |
| `tmux/` | prefix Ctrl+Space, vi nav, escape-time 0 |
| `fcitx5/` | Fcitx5 IME configs (profile, Bamboo Telex, Ctrl+Shift / Alt+Shift toggle) |
| `scripts/` | `~/.local/bin` — CLI utilities (`battery-threshold`, `gm`, `otp`, `mounter`, etc.) |
| `lf/` | lf file manager (vi binds, ueberzug preview, interactive extract/compress) |
| `media/` | mpv, ncmpcpp, mpd configs |
| `opencode/` | 9Router gateway config, 3 combo tiers (KhaBoDo, KhaSimple, KhaThinking) |
| `fontconfig/` | JetBrains Mono Nerd Font, Inter fonts |
| `gtk/` | GTK-3.0, GTK-4.0 settings |
| `yay/` | yay aur helper config |
| `nixos/` | flake.nix, hosts/thinkbox/, home/home.nix |

## Key commands / workflow

- **Deploy:** `stow -vt ~ <package>` (repeat for each package)
- **Undeploy:** `stow -Dvt ~ <package>`
- **Shortcuts:** `shortcuts` regenerates `shortcutrc`/`shortcutenvrc`/`zshnameddirrc` from `bm-dirs`/`bm-files`
- **Git Manager:** `gm` — multi-account git tool under `~/Repos/`, uses git `includeIf`
- **Battery:** `battery-threshold` — sets ThinkPad charge threshold via systemd oneshot service
- **Cron:** `cron/crontog` toggles all cron jobs; `cron/checkup` (pacman), `cron/newsup` (RSS)
- **Setup:** `ka-setup` — post-install helper (PAM keyring, docker, IME, battery)

## Environment

- `EDITOR=nvim`, `VISUAL=nvim`, `BROWSER=brave`, `TERMINAL=alacritty`
- Full XDG dirs set in `shell/.config/shell/profile`
- `ZDOTDIR=$XDG_CONFIG_HOME/zsh`
- vi mode in: zsh, tmux, lf, ncmpcpp, mpv

## Stow quirks

- `scripts/.local/bin/cron/` subdirectory has actual files; `checkup`/`crontog`/`newsup` are symlinks to `cron/*` so they're in PATH + cron jobs can use absolute paths
- `scripts/.local/bin/user/` has bluetooth scripts (`btmgr`, `btpair`, `btclean`, etc.) — kept separate to avoid cluttering the flat namespace
- `.stow-local-ignore` used in `app_desktop/`
- `.gitignore` ignores runtime cache files (`cached_layouts`, etc.) and `shell/.config/shell/profile.local` (used for 9Router API keys)

## NixOS

- `nixos/flake.nix` → `nixosConfigurations.thinkbox` (x86_64-linux, systemd-boot, state 24.11)
- Home-manager with `backupFileExtension = "backup"`
- `home-manager.extraSpecialArgs.dotfiles` points to `/home/ka/.dotfiles`
