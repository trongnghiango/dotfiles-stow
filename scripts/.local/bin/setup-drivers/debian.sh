#!/usr/bin/env bash
# ==============================================================================
# DEBIAN SETUP DRIVER (setup-drivers/debian.sh)
# Mô tả: Driver cài đặt và tối ưu hóa hệ thống cho Debian Linux (Bookworm/Trixie/Sid)
# Thuộc kiến trúc: Omarchy-X11 Layered Profile
# ==============================================================================

# Đảm bảo hàm log khả dụng nếu driver được chạy độc lập
if ! type -t log_info &>/dev/null; then
  log_info()    { echo -e "\033[0;34m[INFO]\033[0m    $1"; }
  log_success() { echo -e "\033[0;32m[OK]\033[0m      $1"; }
  log_warn()    { echo -e "\033[1;33m[WARN]\033[0m    $1"; }
  log_error()   { echo -e "\033[0;31m[ERROR]\033[0m   $1" >&2; }
  log_step()    { echo -e "\n\033[0;36m\033[1m▸ $1\033[0m"; }
  log_dim()     { echo -e "\033[2m  $1\033[0m"; }
fi

# Kiểm tra xem gói apt đã được cài đặt chưa
is_deb_pkg_installed() {
  local pkg="$1"
  dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
}

# ------------------------------------------------------------------------------
# 1. CÀI ĐẶT GÓI APT TỪ PKGS/DEBIAN.CSV
# ------------------------------------------------------------------------------
debian_setup_pkgs() {
  local target="${1:-}"
  local dotfiles_root="${2:-$DOTFILES_DIR}"
  local csv_file="$dotfiles_root/pkgs/debian.csv"

  if [ ! -f "$csv_file" ]; then
    log_error "Không tìm thấy file danh sách gói Debian: $csv_file"
    return 1
  fi

  if ! command -v apt-get &>/dev/null; then
    log_error "Hệ thống không có apt-get. Driver này chỉ dành cho Debian/Ubuntu."
    return 1
  fi

  # Interactive prompt nếu người dùng chạy không tham số tại terminal
  if [ -z "$target" ]; then
    if [ -t 0 ]; then
      echo -e "\033[1mChọn profile gói cài đặt từ pkgs/debian.csv:\033[0m"
      echo -e "  \033[0;32m1) core\033[0m   Nền tảng DWM/X11, Fonts, Shell, Audio, Trình duyệt [Mặc định]"
      echo -e "  \033[0;32m2) dev\033[0m    Công cụ lập trình (Neovim, VSCode, Rust, Clang, Node, LazyGit...)"
      echo -e "  \033[0;32m3) media\033[0m  Nghe nhạc, xem phim, quay màn hình (MPD, ncmpcpp, OBS, yt-dlp...)"
      echo -e "  \033[0;32m4) tools\033[0m  Văn phòng, đọc sách, ghi chú (Pandoc, Calibre, Telegram, Anki...)"
      echo -e "  \033[0;32m5) virt\033[0m   Máy ảo & Containers (Docker, QEMU, Libvirt, Lazydocker...)"
      echo -e "  \033[0;32m6) sys\033[0m    Tiện ích hệ thống mở rộng, Bluetooth, Máy in..."
      echo -e "  \033[0;32m7) all\033[0m    Toàn bộ gói trong danh mục"
      printf "\033[1;33mLựa chọn [1-7] (mặc định 1): \033[0m"
      read -r choice
      case "$choice" in
        2|dev)   target="dev" ;;
        3|media) target="media" ;;
        4|tools) target="tools" ;;
        5|virt)  target="virt" ;;
        6|sys)   target="sys" ;;
        7|all)   target="all" ;;
        *)       target="core" ;;
      esac
    else
      target="core"
    fi
  fi

  log_step "Phân tích danh mục gói Debian cho Profile: '$target'..."

  local apt_pkgs=()
  local external_pkgs=()
  local old_ifs="$IFS"

  while IFS=',' read -r tag name tier deps purpose || [ -n "$name" ]; do
    [[ "$tag" =~ ^[[:space:]]*# ]] && continue
    [ -z "$name" ] && continue

    tag="$(echo "$tag" | tr -d '[:space:]')"
    name="$(echo "$name" | tr -d '[:space:]')"
    tier="$(echo "$tier" | tr -d '[:space:]')"
    deps="$(echo "$deps" | tr -d '[:space:]')"

    local match=false
    if [ "$target" = "all" ]; then
      match=true
    elif [ "$target" = "core" ]; then
      case "$deps" in
        base|x11|dwm|dwm+st|dwm,st|st|dwmblocks|fcitx5|zsh|cli|lf|pipewire|browser|zathura|fonts|intel|system)
          match=true
          ;;
      esac
    elif [ "$target" = "dev" ]; then
      case "$deps" in
        dev|vscode) match=true ;;
      esac
    elif [ "$target" = "media" ]; then
      case "$deps" in
        music|media) match=true ;;
      esac
    elif [ "$target" = "tools" ]; then
      case "$deps" in
        docs|apps|otp|ocr) match=true ;;
      esac
    elif [ "$target" = "virt" ]; then
      [ "$deps" = "docker" ] && match=true
    elif [ "$target" = "sys" ]; then
      case "$deps" in
        intel|bluetooth|system|theme|base) match=true ;;
      esac
    elif [[ "$target" =~ ^[0-9,]+$ ]]; then
      local t_arr=()
      IFS="," read -ra t_arr <<< "$target"
      IFS="$old_ifs"
      for t in "${t_arr[@]}"; do
        [ "$tier" = "$t" ] && match=true && break
      done
    else
      if [[ "$deps" == *"$target"* ]]; then
        match=true
      fi
    fi

    [ "$match" = false ] && continue

    case "$tag" in
      ""|"M"|"B") apt_pkgs+=("$name") ;;
      "E")        external_pkgs+=("$name") ;;
    esac
  done < "$csv_file"
  IFS="$old_ifs"

  # Kiểm tra các gói apt còn thiếu
  local missing_apt=()
  for pkg in "${apt_pkgs[@]}"; do
    if ! is_deb_pkg_installed "$pkg"; then
      missing_apt+=("$pkg")
    fi
  done

  if [ ${#missing_apt[@]} -gt 0 ]; then
    log_info "Profile '$target': Thiếu ${#missing_apt[@]}/${#apt_pkgs[@]} gói APT."
    log_dim "Danh sách thiếu: ${missing_apt[*]}"
    printf "\033[1;33mCập nhật APT và cài đặt gói thiếu? [Y/n]: \033[0m"
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
      sudo apt-get update -y
      if sudo apt-get install -y --no-install-recommends "${missing_apt[@]}"; then
        log_success "Đã cài đặt xong các gói APT."
      else
        log_warn "Một số gói APT không thể cài đặt tự động. Đang thử cài riêng lẻ..."
        for pkg in "${missing_apt[@]}"; do
          if ! is_deb_pkg_installed "$pkg"; then
            sudo apt-get install -y --no-install-recommends "$pkg" || log_warn "Bỏ qua gói: $pkg"
          fi
        done
      fi
    else
      log_warn "Bỏ qua cài đặt gói APT."
    fi
  else
    log_success "Profile '$target': Toàn bộ ${#apt_pkgs[@]} gói APT đã sẵn sàng."
  fi

  # Thông báo về các công cụ External cần bootstrap
  if [ ${#external_pkgs[@]} -gt 0 ]; then
    log_info "Các công cụ hiện đại (External) thuộc profile: ${external_pkgs[*]}"
    debian_setup_modern_tools "${external_pkgs[@]}"
  fi

  # Luôn đồng bộ symlink CLI Debian
  debian_setup_symlinks
}

# ------------------------------------------------------------------------------
# 2. XỬ LÝ KHÁC BIỆT TÊN BINARY DEBIAN (ZERO RUNTIME LATENCY)
# ------------------------------------------------------------------------------
debian_setup_symlinks() {
  log_step "Thiết lập symlink tương thích cho Debian CLI..."
  mkdir -p "$HOME/.local/bin"

  # 1. batcat -> bat
  if command -v batcat &>/dev/null; then
    local bat_bin="$(command -v batcat)"
    if [ ! -e "$HOME/.local/bin/bat" ]; then
      ln -sf "$bat_bin" "$HOME/.local/bin/bat"
      log_success "Đã symlink: $bat_bin → ~/.local/bin/bat"
    else
      log_dim "~/.local/bin/bat đã tồn tại."
    fi
  fi

  # 2. fdfind -> fd
  if command -v fdfind &>/dev/null; then
    local fd_bin="$(command -v fdfind)"
    if [ ! -e "$HOME/.local/bin/fd" ]; then
      ln -sf "$fd_bin" "$HOME/.local/bin/fd"
      log_success "Đã symlink: $fd_bin → ~/.local/bin/fd"
    else
      log_dim "~/.local/bin/fd đã tồn tại."
    fi
  fi
}

# ------------------------------------------------------------------------------
# 3. CÀI ĐẶT HEADER BIÊN DỊCH CHO SUCKLESS (DWM 6.8, ST, DMENU, DWMBLOCKS)
# ------------------------------------------------------------------------------
debian_setup_suckless_deps() {
  log_step "Kiểm tra thư viện phát triển (headers) để biên dịch Suckless trên Debian..."
  local build_pkgs=(
    build-essential
    pkg-config
    libx11-dev
    libx11-xcb-dev
    libxinerama-dev
    libxft-dev
    libimlib2-dev
    libxcb1-dev
    libxcb-res0-dev
    libharfbuzz-dev
    libfontconfig1-dev
    libxrender-dev
    libyajl-dev
    libxext-dev
    libasound2-dev
    libxfixes-dev
    libgtk-3-dev
  )

  local missing_build=()
  for pkg in "${build_pkgs[@]}"; do
    if ! is_deb_pkg_installed "$pkg"; then
      missing_build+=("$pkg")
    fi
  done

  if [ ${#missing_build[@]} -gt 0 ]; then
    log_info "Thiếu ${#missing_build[@]} thư viện C/X11 build headers: ${missing_build[*]}"
    sudo apt-get update -y
    sudo apt-get install -y "${missing_build[@]}"
    log_success "Đã cài đặt đầy đủ build dependencies cho Suckless."
  else
    log_success "Toàn bộ thư viện build headers cho DWM 6.8 và ST đã đầy đủ."
  fi
}

# ------------------------------------------------------------------------------
# 4. BOOTSTRAP CÁC CÔNG CỤ HIỆN ĐẠI (EXTERNAL TOOLS)
# ------------------------------------------------------------------------------
debian_setup_modern_tools() {
  log_step "Kiểm tra và bootstrap công cụ hiện đại (Mise, Neovim, Starship, LF)..."
  mkdir -p "$HOME/.local/bin"

  # 1. Mise Runtime Manager
  if ! command -v mise &>/dev/null && [ ! -f "$HOME/.local/bin/mise" ]; then
    log_info "Đang cài đặt Mise Runtime Manager vào ~/.local/bin..."
    curl -fsSL https://mise.run | sh
    log_success "Đã cài đặt Mise."
  fi

  # 2. Neovim hiện đại (Debian 12 apt chỉ có 0.7.2, dotfiles cần >= 0.9.0)
  if ! command -v nvim &>/dev/null && [ ! -f "$HOME/.local/bin/nvim" ]; then
    log_info "Đang tải Neovim bản mới nhất vào ~/.local/bin/nvim..."
    local nvim_tarball="https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
    local tmp_dir="$(mktemp -d)"
    if curl -fsSL "$nvim_tarball" -o "$tmp_dir/nvim.tar.gz"; then
      tar -xzf "$tmp_dir/nvim.tar.gz" -C "$tmp_dir"
      mkdir -p "$HOME/.local/lib/nvim"
      cp -r "$tmp_dir/nvim-linux64/"* "$HOME/.local/lib/nvim/"
      ln -sf "$HOME/.local/lib/nvim/bin/nvim" "$HOME/.local/bin/nvim"
      log_success "Đã cài đặt Neovim bản mới nhất thành công."
    fi
    rm -rf "$tmp_dir"
  fi

  # 3. Starship Prompt
  if ! command -v starship &>/dev/null && [ ! -f "$HOME/.local/bin/starship" ]; then
    log_info "Đang cài đặt Starship cross-shell prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" >/dev/null
    log_success "Đã cài đặt Starship."
  fi

  # 4. LF File Manager
  if ! command -v lf &>/dev/null && [ ! -f "$HOME/.local/bin/lf" ]; then
    log_info "Đang tải LF terminal file manager binary..."
    local lf_url="https://github.com/gokcehan/lf/releases/latest/download/lf-linux-amd64.tar.gz"
    local tmp_dir="$(mktemp -d)"
    if curl -fsSL "$lf_url" -o "$tmp_dir/lf.tar.gz"; then
      tar -xzf "$tmp_dir/lf.tar.gz" -C "$tmp_dir"
      install -m 755 "$tmp_dir/lf" "$HOME/.local/bin/lf"
      log_success "Đã cài đặt LF vào ~/.local/bin/lf."
    fi
    rm -rf "$tmp_dir"
  fi
}
