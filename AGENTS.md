# AGENTS.md — dotfiles

Personal dotfiles managed with **GNU Stow / stow-safe** + Git.
Primary OS: **Arch Linux + Omarchy (Hyprland / Wayland)** based on a **Hybrid Architecture**.

## Architecture: Hybrid Model

- **Omarchy Core (Desktop / Hardware):** Manages Wayland/Hyprland environment, hardware mounting (`udiskie`), system UI (GTK/Fonts), Clipboard, Bluetooth panel, and Btrfs snapshots.
- **Dotfiles (Terminal Experience):** Custom terminal power-user environment (Zsh, Neovim, Tmux, LF, Fcitx5, Media TUI) safely deployed via `stow-safe` / `ka-setup stow`.

## Structure

Each top-level directory is a Stow package containing `$HOME`-relative paths:

| Package | What |
|---|---|
| `shell/` | `~/.config/shell/`: profile, aliasrc, inputrc (XDG standard) |
| `zsh/` | `~/.config/zsh/`: .zshrc, vi mode, env.zsh |
| `nvim/` | `~/.config/nvim/`: init.lua (modularized), lua/{core,plugins,utils}/ — fully custom |
| `tmux/` | `~/.config/tmux/`: prefix `C-Space`, vi navigation, escape-time 0 |
| `git/` | `~/.config/git/`: config, ignore (aliases, delta diff, rebase, branch/tag sort) |
| `fcitx5/` | `~/.config/fcitx5/`: Fcitx5 IME configs (profile, Bamboo Telex, toggle hotkeys) |
| `scripts/` | `~/.local/bin`: Wayland CLI utilities (`stow-safe`, `ka-setup`, `battery-threshold`, `gm`, `otp`, `weath`, `rssget`, etc.) |
| `lf/` | `~/.config/lf/`: lf file manager (vi binds, ueberzug preview, extract/compress) |
| `hypr/` | `~/.config/hypr/bindings.lua`: DWM Hybrid keybinding overrides |
| `media/` | `~/.config/{mpv,ncmpcpp,mpd}`: PipeWire audio optimizations, TUI music player |
| `opencode/` | `~/.config/opencode/`: 9Router gateway config, 3 combo tiers (KhaBoDo, KhaSimple, KhaThinking) |
| `yay/` | `~/.config/yay/`: yay AUR helper config |

## Key Commands & Workflow

- **Deploy All:** `ka-setup stow` (automates safe deployment with backups via `stow-safe`)
- **Deploy Individual:** `stow-safe -vt ~ <package>` or `stow -vt ~ <package>`
- **Undeploy:** `stow -Dvt ~ <package>`
- **Git Manager:** `gm` — multi-account git manager under `~/Repos/`, uses git `includeIf`
- **Battery:** `battery-threshold` — sets ThinkPad charge thresholds (50-60%) via systemd oneshot service
- **Cron Jobs:** `cron/crontog` toggles cron jobs; `cron/checkup` (pacman), `cron/newsup` (RSS)
- **Setup Helper:** `ka-setup` — post-install helper (`pam`, `docker`, `ime`, `battery`, `gpu-fix`, `shell`, `stow`, `all`)

## Environment & Wayland Standards

- `EDITOR=nvim`, `VISUAL=nvim`, `BROWSER=brave`, `TERMINAL=alacritty`
- Full XDG directories set in `shell/.config/shell/profile`
- `ZDOTDIR=$XDG_CONFIG_HOME/zsh`
- vi mode in: `zsh`, `tmux`, `lf`, `ncmpcpp`, `mpv`
- **CLI Scripting Standards:**
  - Picker: `fzf` (no `dmenu`)
  - Clipboard: `wl-copy` / `wl-paste` (no `xclip`)
  - Image viewer: `imv` (no `nsxiv`)
  - Notifications: `notify-send`

## Stow Quirks & Policies

- `scripts/.local/bin/cron/` subdirectory has actual scripts; `checkup`/`crontog`/`newsup` are symlinks in `scripts/.local/bin/` so they are in PATH and absolute paths work in cron.
- `.stow-local-ignore` used in `app_desktop/`.
- `.gitignore` ignores runtime cache files and `shell/.config/shell/profile.local` (for 9Router API keys).
- **Omarchy Native Policy:** Avoid writing manual X11/DWM scripts. Rely on Omarchy native UI for Bluetooth, drive mounting, clipboard, and system font/theme settings.
