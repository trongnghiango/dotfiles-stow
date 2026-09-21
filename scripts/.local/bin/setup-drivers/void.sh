#!/usr/bin/env bash
# ==============================================================================
# VOID LINUX SETUP DRIVER (setup-drivers/void.sh)
# Mô tả: Driver cài đặt gói cho Void Linux qua XBPS (xbps-install)
# Thuộc kiến trúc: Omarchy-X11 Layered Profile
# ==============================================================================

if ! type -t log_info &>/dev/null; then
  log_info()    { echo -e "\033[0;34m[INFO]\033[0m    $1"; }
  log_success() { echo -e "\033[0;32m[OK]\033[0m      $1"; }
  log_warn()    { echo -e "\033[1;33m[WARN]\033[0m    $1"; }
  log_error()   { echo -e "\033[0;31m[ERROR]\033[0m   $1" >&2; }
  log_step()    { echo -e "\n\033[0;36m\033[1m▸ $1\033[0m"; }
  log_dim()     { echo -e "\033[2m  $1\033[0m"; }
fi

void_setup_suckless_deps() {
  log_step "Kiểm tra thư viện phát triển (headers) để biên dịch Suckless trên Void..."
  local build_pkgs=(
    base-devel
    pkg-config
    libX11-devel
    libXinerama-devel
    libXft-devel
    libimlib2-devel
    libxcb-devel
    harfbuzz-devel
    fontconfig-devel
    libXrender-devel
    yajl-devel
    libXext-devel
    alsa-lib-devel
    libXfixes-devel
    gtk+3-devel
  )

  local missing_build=()
  for pkg in "${build_pkgs[@]}"; do
    if ! xbps-query -s "$pkg" | grep -q "^[*] $pkg-[0-9]"; then
      missing_build+=("$pkg")
    fi
  done

  if [ ${#missing_build[@]} -gt 0 ]; then
    log_info "Thiếu ${#missing_build[@]} thư viện C/X11 build headers: ${missing_build[*]}"
    sudo xbps-install -y "${missing_build[@]}"
    log_success "Đã cài đặt đầy đủ build dependencies cho Suckless."
  else
    log_success "Toàn bộ thư viện build headers cho DWM 6.8 và ST đã đầy đủ."
  fi
}

void_setup_pkgs() {
  local target="${1:-}"
  local dotfiles_root="${2:-$DOTFILES_DIR}"
  local progs_file="$dotfiles_root/pkgs/void.csv"

  if [ ! -f "$progs_file" ]; then
    log_error "Không tìm thấy file danh sách gói Void: $progs_file"
    return 1
  fi

  if ! command -v xbps-install &>/dev/null; then
    log_warn "Hệ thống không dùng xbps — bỏ qua bước cài đặt Void."
    return 0
  fi

  if [ -z "$target" ]; then
    if [ -t 0 ]; then
      echo -e "\033[1mChọn profile gói cài đặt cho Void Linux:\033[0m"
      echo -e "  \033[0;32m1) core\033[0m   Nền tảng DWM/X11, Fonts, Shell, Audio [Mặc định]"
      echo -e "  \033[0;32m2) dev\033[0m    Công cụ lập trình (Clang, Git-delta, Mise...)"
      echo -e "  \033[0;32m3) media\033[0m  Nghe nhạc, xem phim (MPV, ALSA, PipeWire...)"
      echo -e "  \033[0;32m4) tools\033[0m  Tiện ích văn phòng (Zathura, OCR...)"
      echo -e "  \033[0;32m5) all\033[0m    Toàn bộ gói trong danh mục"
      printf "\033[1;33mLựa chọn [1-5] (mặc định 1): \033[0m"
      read -r choice
      case "$choice" in
        2|dev)   target="dev" ;;
        3|media) target="media" ;;
        4|tools) target="tools" ;;
        5|all)   target="all" ;;
        *)       target="core" ;;
      esac
    else
      target="core"
    fi
  fi

  local void_arch
  if command -v xbps-uhelper &>/dev/null; then
    void_arch="$(xbps-uhelper arch 2>/dev/null || uname -m)"
  else
    void_arch="$(uname -m)"
  fi
  log_info "Kiến trúc hệ thống Void: ${void_arch}"
  log_step "Đang đọc danh mục gói Void Linux ($target) từ: $progs_file"

  local pkgs_to_install=()
  while IFS=, read -r tag name tier deps purpose; do
    [[ "$tag" =~ ^#.*$ ]] && continue
    [ -z "$name" ] && continue

    case "$target" in
      core)
        [[ "$tier" =~ ^[1236]$ ]] && pkgs_to_install+=("$name")
        ;;
      dev)
        [[ "$tier" =~ ^[145]$ ]] && pkgs_to_install+=("$name")
        ;;
      media)
        [[ "$tier" =~ ^[18]$ ]] && pkgs_to_install+=("$name")
        ;;
      tools)
        [[ "$tier" =~ ^[178]$ ]] && pkgs_to_install+=("$name")
        ;;
      all)
        pkgs_to_install+=("$name")
        ;;
      *)
        if [[ "$target" =~ ^[0-9]+$ ]] && [ "$tier" = "$target" ]; then
          pkgs_to_install+=("$name")
        fi
        ;;
    esac
  done < "$progs_file"

  if [ ${#pkgs_to_install[@]} -eq 0 ]; then
    log_warn "Không tìm thấy gói nào phù hợp với profile '$target'."
    return 0
  fi

  log_info "Tổng số gói cần cài đặt: ${#pkgs_to_install[@]}"
  log_step "Tiến hành cài đặt qua xbps-install..."
  sudo xbps-install -Sy "${pkgs_to_install[@]}"
  log_success "Hoàn tất cài đặt gói Void Linux!"
}
