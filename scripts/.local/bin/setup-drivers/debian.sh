#!/usr/bin/env bash
# ==============================================================================
# DEBIAN SERVER-MINIMAL DRIVER (setup-drivers/debian.sh)
# Mô tả: Cài gói CLI tối giản cho server hosting từ pkgs/server.csv.
# Không đụng tới X11/desktop/audio/bluetooth.
# ==============================================================================

# Log functions nếu chạy độc lập
if ! type -t log_info &>/dev/null; then
  log_info()    { echo -e "\033[0;34m[INFO]\033[0m    $1"; }
  log_success() { echo -e "\033[0;32m[OK]\033[0m      $1"; }
  log_warn()    { echo -e "\033[1;33m[WARN]\033[0m    $1"; }
  log_error()   { echo -e "\033[0;31m[ERROR]\033[0m   $1" >&2; }
  log_step()    { echo -e "\n\033[0;36m\033[1m▸ $1\033[0m"; }
  log_dim()     { echo -e "\033[2m  $1\033[0m"; }
fi

is_deb_pkg_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

# ------------------------------------------------------------------------------
# 1. CÀI GÓI TỪ PKGS/SERVER.CSV
# ------------------------------------------------------------------------------
debian_setup_pkgs() {
  local dotfiles_root="${2:-${DOTFILES_DIR:-$HOME/dotfiles-stow}}"
  local csv_file="$dotfiles_root/pkgs/server.csv"

  if [ ! -f "$csv_file" ]; then
    log_error "Không tìm thấy danh sách gói server: $csv_file"
    return 1
  fi

  if ! command -v apt-get &>/dev/null; then
    log_error "Hệ thống không có apt-get. Driver này chỉ dành cho Debian/Ubuntu."
    return 1
  fi

  log_step "Phân tích pkgs/server.csv..."
  local apt_pkgs=()
  local external_pkgs=()

  while IFS=',' read -r tag name tier deps purpose || [ -n "$name" ]; do
    [[ "$tag" =~ ^[[:space:]]*# ]] && continue
    [ -z "$name" ] && continue
    tag="$(echo "$tag" | tr -d '[:space:]')"
    name="$(echo "$name" | tr -d '[:space:]')"
    [ -z "$name" ] && continue
    case "$tag" in
      ""|"M"|"B") apt_pkgs+=("$name") ;;
      "E")        external_pkgs+=("$name") ;;
    esac
  done < "$csv_file"

  # Lọc gói còn thiếu
  local missing=()
  for pkg in "${apt_pkgs[@]}"; do
    if ! is_deb_pkg_installed "$pkg"; then
      missing+=("$pkg")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    log_info "Thiếu ${#missing[@]}/${#apt_pkgs[@]} gói. Đang cài đặt..."
    log_dim "${missing[*]}"
    sudo apt-get update -y
    if ! sudo apt-get install -y --no-install-recommends "${missing[@]}"; then
      log_warn "Cài hàng loạt lỗi. Thử cài từng gói..."
      for pkg in "${missing[@]}"; do
        is_deb_pkg_installed "$pkg" || sudo apt-get install -y --no-install-recommends "$pkg" \
          || log_warn "Bỏ qua gói: $pkg"
      done
    fi
    log_success "Hoàn tất cài gói APT."
  else
    log_success "Toàn bộ ${#apt_pkgs[@]} gói đã có sẵn."
  fi

  if [ ${#external_pkgs[@]} -gt 0 ]; then
    log_warn "Gói external (chưa hỗ trợ tự động): ${external_pkgs[*]}"
  fi

  debian_setup_symlinks
  debian_setup_nvim
}

# ------------------------------------------------------------------------------
# 2. SYMLINK TƯƠNG THÍCH DEBIAN (batcat/fdfind)
# ------------------------------------------------------------------------------
debian_setup_symlinks() {
  mkdir -p "$HOME/.local/bin"

  if command -v batcat &>/dev/null && [ ! -e "$HOME/.local/bin/bat" ]; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    log_dim "symlink: batcat → ~/.local/bin/bat"
  fi

  if command -v fdfind &>/dev/null && [ ! -e "$HOME/.local/bin/fd" ]; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    log_dim "symlink: fdfind → ~/.local/bin/fd"
  fi
}

# ------------------------------------------------------------------------------
# 3. NEOVIM >= 0.11 (config dùng winborder / vim.diagnostic.jump)
# ------------------------------------------------------------------------------
debian_setup_nvim() {
  command -v nvim &>/dev/null || return 0

  local ver major minor
  ver="$(nvim --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
  major="${ver%%.*}"
  minor="$(printf '%s' "$ver" | cut -d. -f2)"
  if [ -n "$ver" ] && { [ "${major:-0}" -gt 0 ] || [ "${minor:-0}" -ge 11 ]; }; then
    return 0
  fi

  log_info "Neovim ${ver:-unknown} < 0.11 — tải bản mới vào ~/.local..."
  local tmp
  tmp="$(mktemp -d)"
  if curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -o "$tmp/nvim.tar.gz"; then
    tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
    mkdir -p "$HOME/.local/lib/nvim"
    cp -r "$tmp"/nvim-linux-x86_64/* "$HOME/.local/lib/nvim/" 2>/dev/null \
      || cp -r "$tmp"/nvim-linux64/* "$HOME/.local/lib/nvim/" 2>/dev/null
    ln -sf "$HOME/.local/lib/nvim/bin/nvim" "$HOME/.local/bin/nvim"
    log_success "Đã cài Neovim mới vào ~/.local/bin/nvim."
  else
    log_warn "Không tải được Neovim mới. Giữ bản APT."
  fi
  rm -rf "$tmp"
}
