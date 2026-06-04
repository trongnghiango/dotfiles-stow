# Shell & Zsh Configuration Report

Cấu hình shell/zsh trong dotfiles (`shell/` và `zsh/`) — phân tích chi tiết về chức năng và phạm vi can thiệp.

---

## Tổng quan cấu trúc

```
shell/
├── .zprofile                          # entry point login shell
└── .config/shell/
    ├── profile                        # biến môi trường XDG + chương trình mặc định
    ├── aliasrc                        # aliases chung (cross-platform)
    ├── aliasrc.arch                   # aliases dành riêng cho Arch Linux
    ├── aliasrc.void                   # aliases dành riêng cho Void Linux
    ├── aliasrc.nixos                  # aliases dành riêng cho NixOS
    ├── shortcutrc                     # cd shortcuts (alias dạng chữ)
    ├── shortcutenvrc                  # biến môi trường cho shortcut path
    ├── zshnameddirrc                  # named directories cho zsh (hash -d)
    ├── inputrc                        # readline config (vi mode)
    ├── bm-files                       # bookmark files cho lf/vim plugin
    └── bm-dirs                        # bookmark directories

zsh/
├── .config/zsh/.zshrc                 # main zsh config
└── .local/bin/append_zshrc            # script phụ để thêm nội dung vào .zshrc
```

---

## 1. `shell/.zprofile` — Entry point

```sh
source "$HOME/.config/shell/profile"
```

- **Kích hoạt khi:** Zsh login shell khởi động (tty1 login, `zsh -l`, `startx` từ console)
- **Việc duy nhất:** source `profile`
- **Can thiệp:** Chi phối những gì được nạp trước khi zshrc chạy

---

## 2. `shell/.config/shell/profile` — Biến môi trường nền tảng

| Section | Dòng | Làm gì | Can thiệp vào |
|---------|------|--------|---------------|
| PATH | 8-10 | Thêm `~/.local/bin` vào `$PATH` | Mọi lệnh từ user scripts |
| PATH | 12 | Thêm `~/Applications/bin` vào `$PATH` | Ứng dụng GUI/local |
| Editor/Terminal/Browser | 17-20 | `EDITOR=nvim`, `TERMINAL=st`, `BROWSER=brave` | Git, crontab, systemd, mọi tool gọi editor |
| XDG dirs | 27-29 | `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME` | Mọi ứng dụng hiểu XDG |
| XINITRC | 30 | `export XINITRC="$XDG_CONFIG_HOME/x11/xinitrc"` | `startx` dùng file này |
| NOTMUCH_CONFIG | 32 | `$XDG_CONFIG_HOME/notmuch-config` | Notmuch (email) |
| GTK2_RC_FILES | 33 | `$XDG_CONFIG_HOME/gtk-2.0/gtkrc-2.0` | GTK2 apps |
| WGETRC | 34 | `$XDG_CONFIG_HOME/wget/wgetrc` | wget |
| INPUTRC | 35 | `$XDG_CONFIG_HOME/shell/inputrc` | Readline (bash, psql, python...) |
| ZDOTDIR | 36 | `$XDG_CONFIG_HOME/zsh` | Zsh config path |
| WINEPREFIX | 38 | `$XDG_DATA_HOME/wineprefixes/default` | Wine |
| KODI_DATA | 39 | `$XDG_DATA_HOME/kodi` | Kodi |
| PASSWORD_STORE_DIR | 40 | `$XDG_DATA_HOME/password-store` | pass |
| CARGO_HOME | 43 | `$XDG_DATA_HOME/cargo` | Rust/Cargo |
| GOMODCACHE | 44 | `$XDG_CACHE_HOME/go/mod` | Go modules cache |
| ANSIBLE_CONFIG | 45 | `$XDG_CONFIG_HOME/ansible/ansible.cfg` | Ansible |
| PYTHONSTARTUP | 50 | `$XDG_CONFIG_HOME/python/pythonrc` | Python REPL |
| MBSYNCRC | 48 | `$XDG_CONFIG_HOME/mbsync/config` | mbsync (email) |
| LESS | 56-66 | Màu sắc, highlight cho less | `less`, `man`, `git diff` |
| QT_QPA_PLATFORMTHEME | 67 | `gtk2` | Ứng dụng Qt (Obsidian, qBittorrent...) |
| MOZ_USE_XINPUT2 | 68 | `1` | Firefox/Floorp scroll mượt |
| _JAVA_AWT_WM_NONREPARENTING | 70 | `1` | Java apps trong dwm |
| Auto startx | 73 | `[ "$(tty)" = "/dev/tty1" ] && exec startx "$XINITRC"` | Tự boot X khi login tty1 |
| Keyboard | 76 | `loadkeys remap Esc/Caps` | Console tty |

### Điểm đáng chú ý

- `ZDOTDIR` : chuyển zsh config từ `~/.zshrc` sang `~/.config/zsh/.zshrc`
- `INPUTRC` : chuyển readline config sang `~/.config/shell/inputrc`
- Auto startx : nếu login ở tty1 và X chưa chạy → `exec startx` ngay
- `GOPATH` được set trong `.zshrc` (`$HOME/go`), không phải profile

---

## 3. `zsh/.config/zsh/.zshrc` — Cấu hình Zsh chính

### 3a. Prompt & shell options (dòng 1-8)

```sh
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@...%{$fg[blue]%}%M ...]%{$reset_color%}$%b "
```

- Prompt màu: `[user@host ~]$`
- `setopt autocd` — gõ tên thư mục để cd
- `stty stop undef` — tắt Ctrl+S freeze (tránh conflict với vim)
- `setopt interactive_comments` — cho phép comment trong lệnh

### 3b. History (dòng 11-26)

- File: `$HOME/.cache/zsh/history` (theo XDG)
- `HISTSIZE=SAVEHIST=10,000,000`
- Options:
  - `APPEND_HISTORY` — giữa các tab, không ghi đè
  - `INC_APPEND_HISTORY` — ghi realtime, không đợi đến khi thoát
  - `SHARE_HISTORY` — chia sẻ history giữa tất cả terminal
  - `HIST_IGNORE_DUPS` — bỏ qua lệnh trùng
  - `HIST_REDUCE_BLANKS` — nén khoảng trắng thừa

### 3c. Source các file shell config (dòng 29-41)

Thứ tự: `shortcutrc` → `shortcutenvrc` → `aliasrc` → OS detection → `zshnameddirrc`

```sh
[ -f ".../shortcutrc" ]     && source ".../shortcutrc"
[ -f ".../shortcutenvrc" ]  && source ".../shortcutenvrc"
[ -f ".../aliasrc" ]        && source ".../aliasrc"

# OS-specific aliases (arch / void / nixos)
if [ -f /etc/os-release ]; then
  OS=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
  OS_ALIASRC=".../aliasrc.$OS"
  [ -f "$OS_ALIASRC" ] && source "$OS_ALIASRC"
fi

[ -f ".../zshnameddirrc" ]  && source ".../zshnameddirrc"
```

- Sau khi source `aliasrc` chung, tự động detect OS từ `/etc/os-release` và source `aliasrc.arch` / `aliasrc.void` / `aliasrc.nixos` tương ứng
- Pattern giống `xinitrc.$OS` — khi cài OS mới chỉ cần tạo `aliasrc.<tên_os>`

### 3d. Autocomplete (dòng 35-40)

```sh
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)
```

- Menu select dùng phím mũi tên
- `globdots` — tab complete hiện file ẩn

### 3e. Vi mode & keybindings (dòng 42-92)

| Item | Giá trị | Mục đích |
|------|---------|----------|
| `bindkey -v` | — | Vi mode cho command line |
| `KEYTIMEOUT=1` | 10ms | Chuyển mode ngay lập tức (default 400ms) |
| Cursor normal | Block (`\e[1 q`) | Chế độ normal (vim) |
| Cursor insert | Beam (`\e[5 q`) | Chế độ insert |

**Custom keybindings:**

| Phím | Action | Gọi tool |
|------|--------|----------|
| `Ctrl+O` | `lfcd` — file manager chọn dir | lf |
| `Ctrl+A` | Calculator | bc -lq |
| `Ctrl+F` | cd vào dir từ fuzzy finder | fzf |
| `Ctrl+E` | Edit command line hiện tại | nvim |
| Tab complete | `hjkl` để di chuyển | zsh/complist |

### 3f. NVM — lazy load (dòng 94-105)

```sh
export NVM_DIR="$HOME/.config/nvm"

_nvm_lazy_load() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

nvm() { _nvm_lazy_load; nvm "$@"; }
node() { _nvm_lazy_load; node "$@"; }
npm() { _nvm_lazy_load; npm "$@"; }
npx() { _nvm_lazy_load; npx "$@"; }
```

- **Lazy loading:** Chỉ load nvm khi gõ `nvm`, `node`, `npm`, hoặc `npx` lần đầu — tiết kiệm ~200ms mỗi terminal
- `_nvm_lazy_load` tự huỷ các hàm giả (`unset -f`), source `nvm.sh` thật, lần sau gọi binary thật trong PATH
- Dữ liệu ở `~/.config/nvm` thay vì `~/.nvm`

### 3g. FZF (dòng 98-103)

```sh
export FZF_DEFAULT_OPTS="--height=40% --border --reverse --info=inline"
```

- 40% chiều cao, border, reverse layout, inline info

### 3h. pnpm (dòng 105-110)

```sh
export PNPM_HOME="/home/ka/.local/share/pnpm"
```

- Thêm `pnpm` bin vào PATH

### 3i. Go (dòng 112-114)

```sh
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
```

- `GOPATH` ở `$HOME/go` (khác với `GOMODCACHE` ở profile là `$XDG_CACHE_HOME/go/mod`)

### 3j. Bun (dòng 116-117)

```sh
[ -s "/home/ka/.bun/_bun" ] && source "/home/ka/.bun/_bun"
```

- Load bun completions

### 3k. Direnv (dòng 119)

```sh
eval "$(direnv hook zsh)"
```

- **Can thiệp:** Auto load/unload env vars khi cd vào thư mục có `.envrc`

### 3l. Fast syntax highlighting (dòng 121-122)

```sh
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
```

- Đặt **cuối cùng** (theo yêu cầu plugin)
- Highlight realtime: lệnh đúng (xanh), sai (đỏ), path tồn tại (gạch chân)

---

## 4. `shell/.config/shell/aliasrc` — Aliases chung

Aliases được tách làm 2 lớp: **chung** (`aliasrc`) và **OS-specific** (`aliasrc.arch`, `aliasrc.void`, `aliasrc.nixos`).

### 4a. Override lệnh

| Alias | Gọi | Mục đích |
|-------|-----|----------|
| `vim` | `nvim` | Neovim thay thế vim |
| `startx` | `startx $XINITRC` | Dùng đúng xinitrc path |
| `mbsync` | `mbsync -c $MBSYNCRC` | Dùng đúng config path |

### 4b. Sudo wrapper (chung)

```sh
for command in mount umount updatedb su shutdown poweroff reboot; do
  alias $command="sudo $command"
done
```

**Can thiệp:** mount, umount, shutdown, reboot... luôn chạy sudo (cross-platform). `pacman` (Arch) và `sv` (Void) được chuyển xuống file OS-specific.

### 4c. Interactive safety aliases

| Alias | Flags | Tác dụng |
|-------|-------|----------|
| `cp` | `-iv` | Hỏi trước ghi đè, verbose |
| `mv` | `-iv` | Hỏi trước ghi đè, verbose |
| `rm` | `-vI` | Hỏi nếu >3 files |
| `mkd` | `-pv` | Tạo nested directory, verbose |

### 4d. ls với eza

- `eza` available → `eza --icons --group-directories-first`
- fallback → `ls -hN --color=auto --group-directories-first`

### 4e. Short aliases (chung)

| Alias | Gọi |
|-------|-----|
| `ka` | `killall` |
| `g` | `git` |
| `e`/`v` | `$EDITOR` (nvim) |
| `sdn` | `shutdown -h now` |
| `lf` | `lfub` |
| `magit` | `nvim -c MagitOnly` |
| `ref` | refresh shortcuts |

---

## 4x. OS-specific alias files

### `aliasrc.arch` (Arch Linux)

| Alias | Gọi |
|-------|-----|
| `p` | `pacman` |
| `pacman` | `sudo pacman` |

### `aliasrc.void` (Void Linux)

| Alias | Gọi |
|-------|-----|
| `xi` | `sudo xbps-install` |
| `xr` | `sudo xbps-remove -R` |
| `xq` | `xbps-query` |
| `sv` | `sudo sv` |

### `aliasrc.nixos` (NixOS)

| Alias | Gọi |
|-------|-----|
| `nrs` | `sudo nixos-rebuild switch` |
| `nrt` | `sudo nixos-rebuild test` |
| `nu` | `nix-env -u` |
| `nq` | `nix-env -q` |
| `ni` | `nix-env -i` |
| `ne` | `nix-env -e` |
| `nc` | `nix-collect-garbage` |
| `ncf` | `nix-collect-garbage -d` |

---

## 5. `shortcutrc` / `shortcutenvrc` / `zshnameddirrc` — Navigation

### 5a. shortcutrc — cd aliases

| Alias | Dir | Config editor alias | File |
|-------|-----|-------------------|------|
| `cac` | `~/.cache` | `cfx` | xresources |
| `cf` | `~/.config` | `cfz` | .zshrc |
| `D` | `~/Downloads` | `cfa` | aliasrc |
| `d` | `~/Documents` | `cfp` | profile |
| `dt` | `~/.local/share` | `cfv` | init.vim |
| `rr`/`src` | `~/.local/src` | `cfl` | lfrc |
| `h` | `~` | `cfm` | muttrc |
| `m` | `~/Music` | `cfn`/`cfu` | newsboat |
| `mn` | `/mnt` | `cfL` | lf scope |
| `pp` | `~/Pictures` | `cfmb`/`cfmc` | ncmpcpp |
| `sc` | `~/.local/bin` | `cfX` | nsxiv handler |
| `vv` | `~/Videos` | `bf`/`bd` | bm-files/dirs |

### 5b. shortcutenvrc — Biến export

Cho phép dùng `$cf`, `$d`, `$pp`, `$sc`... trong lệnh (vd: `cp file $d/`).

### 5c. zshnameddirrc — Named directories

Cho phép dùng `~cf`, `~d`, `~pp`... thay path dài trong cd, cp, mv.

**3 file này đồng bộ 100%** — alias cd + env var + named dir cho cùng paths.

---

## 6. `shell/.config/shell/inputrc` — Readline config

```sh
set editing-mode vi
set show-mode-in-prompt on
set vi-ins-mode-string \1\e[6 q\2
set vi-cmd-mode-string \1\e[2 q\2
```

- `editing-mode vi` — vi mode cho mọi ứng dụng readline
- `show-mode-in-prompt` — hiển thị insert/normal mode

**Can thiệp:** Bash, Python REPL, psql, mysql, irb, bc, ftp, sftp, và mọi tool dùng readline.

---

## 7. `bm-files` / `bm-dirs` — Bookmark cho file manager

Định dạng: `key	path	# comment`

Dùng bởi lf (`:open bookmark`) và plugin shortcuts.

---

## 8. `append_zshrc` — Utility script (`zsh/.local/bin/append_zshrc`)

Script bash tương tác để thêm nội dung vào `.zshrc`:

1. **Auto-detect** — tìm file ở 3 vị trí: dotfiles → stow → legacy
2. **Symlink-aware** — nếu file là symlink, ghi vào target
3. **Preview + confirm** — hiển thị nội dung trước khi ghi
4. **Backup** — tự động backup trước khi sửa
5. **Stow hint** — nhắc `stow -t ~ -R zsh` nếu cần

**Use case:** Tool cho developer, tránh mở editor khi cần thêm nhanh config.

---

## Chuỗi khởi tạo (init chain)

```
Login (tty1)
  ↓
.zprofile
  ↓
.profile  ─── nạp biến môi trường nền tảng (XDG, PATH, editor...)
  ↓
[ tty1 + X chưa chạy? ] ─→ exec startx $XINITRC → X11
  ↓ (nếu không vào X)
.zshrc    ─── source shell files, vi mode, completion, tools
  ↓
shortcutrc / shortcutenvrc / aliasrc → [OS detect] aliasrc.{arch,void,nixos} / zshnameddirrc
  ↓
NVM (lazy) → FZF → pnpm → Go → bun → direnv → fast-syntax-highlighting
  ↓
Prompt sẵn sàng
```

---

## Tổng kết can thiệp chính

| Thành phần | Can thiệp vào | Mức độ |
|------------|---------------|--------|
| XDG vars (`CONFIG`/`DATA`/`CACHE`) | Hầu hết ứng dụng Linux | 🔴 Cao |
| `ZDOTDIR` | Zsh config path | 🔴 Cao |
| `INPUTRC` | Readline apps (bash, psql, python...) | 🔴 Cao |
| `EDITOR=nvim` | Git, systemd, crontab, man | 🔴 Cao |
| Vi mode | Zsh command line + readline | 🔴 Cao |
| Auto startx | Tự vào X ở tty1 | 🔴 Cao |
| Direnv | Auto env theo thư mục | 🟡 Trung bình |
| NVM (lazy) | Chỉ load khi dùng Node | 🟢 Nhẹ |
| Sudo aliases | mount/umount/shutdown... (tuỳ OS) | 🟡 Trung bình |
| Safety aliases (cp/mv/rm) | Hành vi copy/move/delete | 🟡 Trung bình |
| `QT_QPA_PLATFORMTHEME` | Ứng dụng Qt (Obsidian...) | 🟢 Nhẹ |
| `_JAVA_AWT_WM_NONREPARENTING` | Java apps trong dwm | 🟢 Nhẹ |
| `MOZ_USE_XINPUT2` | Firefox scroll mượt | 🟢 Nhẹ |
| fast-syntax-highlighting | Zsh input realtime | 🟢 Nhẹ |
| Shortcut cd/env/named | Navigation trong shell | 🟢 Nhẹ |

---

## Lịch sử sửa đổi

### 2026-06-04 — Refactor shell/zsh config (commit `f696f35`)

#### `shell/.config/shell/profile`
- **Fix bug** dòng 12: sửa điều kiện `[ -d "$HOME/.local/bin" ]` → `[ -d "$HOME/Applications/bin" ]` (sai logic kiểm tra thư mục)
- **Xoá** `export GOPATH="$XDG_DATA_HOME/go"` — chuyển về `.zshrc` (`$HOME/go`)
- **Xoá** `export FZF_DEFAULT_OPTS` — chuyển về `.zshrc` (bản chi tiết hơn)

#### `shell/.config/shell/shortcutenvrc`
- **Đồng bộ:** `~/.local/src/dwmblocks/config.h` → `$HOME/.local/src/dwmblocks/config.h`

#### `shell/.config/shell/zshnameddirrc`
- **Đồng bộ:** `~/.local/src/dwmblocks/config.h` → `$HOME/.local/src/dwmblocks/config.h`

#### `shell/.config/shell/aliasrc` — Tách OS-specific
- **Xoá** `sv` và `pacman` khỏi vòng lặp sudo wrapper (chuyển xuống file OS-specific)
- **Xoá** `p`, `xi`, `xr`, `xq` khỏi short aliases (chuyển xuống file OS-specific)
- Thêm OS detection vào `.zshrc` để source `aliasrc.$OS`

#### File mới: `aliasrc.arch`
- `p` → `pacman`, `pacman` → `sudo pacman`

#### File mới: `aliasrc.void`
- `xi` → `sudo xbps-install`, `xr` → `sudo xbps-remove -R`, `xq` → `xbps-query`
- `sv` → `sudo sv`

#### File mới: `aliasrc.nixos`
- `nrs`/`nrt` → nixos-rebuild, `nu`/`nq`/`ni`/`ne` → nix-env, `nc`/`ncf` → nix-collect-garbage

#### `zsh/.config/zsh/.zshrc`
- **Xoá** block duplicate `compinit` (do `append_zshrc` thêm vào trước đó)
- **Thêm** OS detection sau khi source `aliasrc`
- **Sắp xếp lại thứ tự:** NVM → FZF → pnpm → Go → bun → direnv → fast-syntax-highlighting
- **Chuyển** fast-syntax-highlighting xuống cuối cùng (đúng theo yêu cầu plugin)
- **Thay thế** NVM eager load bằng lazy load — chỉ source `nvm.sh` khi gõ `nvm`/`node`/`npm`/`npx` lần đầu

### 2026-06-04 — File report được tạo
- `docs/shell-zsh-report.md` — report chi tiết về cấu hình shell/zsh
