#!/usr/bin/env bash
# ==============================================================================
# ARCH LINUX SETUP DRIVER (setup-drivers/arch.sh)
# Mô tả: Driver cài đặt gói cho Arch Linux qua Pacman và AUR Helper (yay/paru)
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

arch_get_aur_helper() {
  if command -v yay &>/dev/null; then
    echo "yay"
    return 0
  fi
  if command -v paru &>/dev/null; then
    echo "paru"
    return 0
  fi

  log_info "Chưa tìm thấy yay/paru. Tự động biên dịch yay-bin từ AUR..."
  local build_dir
  build_dir="$(mktemp -d)"
  if git clone https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin"; then
    (
      cd "$build_dir/yay-bin"
      makepkg -si --noconfirm
    )
    rm -rf "$build_dir"
    if command -v yay &>/dev/null; then
      log_success "Đã cài đặt yay-bin thành công."
      echo "yay"
      return 0
    fi
  fi
  rm -rf "$build_dir"
  log_warn "Không thể tự động cài đặt yay-bin. Cần cài thủ công."
  return 1
}

arch_setup_suckless_deps() {
  log_step "Kiểm tra thư viện phát triển (headers) để biên dịch Suckless trên Arch..."
  local build_pkgs=(
    base-devel
    pkgconf
    libx11
    libxinerama
    libxft
    imlib2
    libxcb
    harfbuzz
    fontconfig
    libxrender
    yajl
    libxext
    alsa-lib
    libxfixes
    gtk3
  )

  local missing_build=()
  for pkg in "${build_pkgs[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null 2>&1; then
      missing_build+=("$pkg")
    fi
  done

  if [ ${#missing_build[@]} -gt 0 ]; then
    log_info "Thiếu ${#missing_build[@]} thư viện C/X11 build dependencies: ${missing_build[*]}"
    sudo pacman -S --needed --noconfirm "${missing_build[@]}"
    log_success "Đã cài đặt đầy đủ build dependencies cho Suckless."
  else
    log_success "Toàn bộ thư viện build headers cho DWM 6.8 và ST đã đầy đủ."
  fi
}

arch_setup_pkgs() {
  local target="${1:-}"
  local dotfiles_root="${2:-$DOTFILES_DIR}"
  local progs_file="$dotfiles_root/pkgs/arch.csv"

  if [ ! -f "$progs_file" ]; then
    log_error "Không tìm thấy file danh sách gói Arch: $progs_file"
    return 1
  fi

  if ! command -v pacman &>/dev/null; then
    log_warn "Hệ thống không dùng pacman — bỏ qua bước cài đặt Arch."
    return 0
  fi

  # Interactive prompt nếu người dùng chạy không tham số tại terminal
  if [ -z "$target" ]; then
    if [ -t 0 ]; then
      echo -e "\033[1mChọn profile gói cài đặt từ progs.csv:\033[0m"
      echo -e "  \033[0;32m1) core\033[0m   Nền tảng DWM/X11, Fonts, Shell, Audio, Trình duyệt [Mặc định]"
      echo -e "  \033[0;32m2) dev\033[0m    Công cụ lập trình (Neovim, VSCode, Rust, Clang, Node, LazyGit...)"
      echo -e "  \033[0;32m3) media\033[0m  Nghe nhạc, xem phim, quay màn hình (MPD, ncmpcpp, OBS, yt-dlp...)"
      echo -e "  \033[0;32m4) tools\033[0m  Văn phòng, đọc sách, ghi chú (Pandoc, Calibre, Telegram, Anki...)"
      echo -e "  \033[0;32m5) virt\033[0m   Máy ảo & Containers (Docker, QEMU, Libvirt, Lazydocker...)"
      echo -e "  \033[0;32m6) sys\033[0m    Tiện ích hệ thống mở rộng, Bluetooth, Máy in..."
      echo -e "  \033[0;32m7) all\033[0m    Toàn bộ 200+ gói trong progs.csv"
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

  log_step "Lọc danh sách gói theo profile [$target] từ $progs_file..."

  local pacman_pkgs=()
  local aur_pkgs=()

  local old_ifs="$IFS"
  while IFS=, read -r tag name tier deps purpose || [ -n "$name" ]; do
    [[ -z "$name" || "$tag" =~ ^# ]] && continue
    tag="${tag// /}"
    name="${name// /}"
    tier="${tier// /}"
    deps="${deps// /}"

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
      ""|"M") pacman_pkgs+=("$name") ;;
      "A")    aur_pkgs+=("$name") ;;
      "G")    ;;
    esac
  done < "$progs_file"
  IFS="$old_ifs"

  # 1. Gói pacman
  local missing=()
  for pkg in "${pacman_pkgs[@]}"; do
    if ! pacman -Qi "$pkg" &>/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    log_info "Profile '$target': Thiếu ${#missing[@]}/${#pacman_pkgs[@]} gói pacman."
    log_dim "Gói thiếu: ${missing[*]}"
    printf "\033[1;33mCài đặt? [Y/n]: \033[0m"
    read -r ans
    if [[ ! "$ans" =~ ^[Nn] ]]; then
      if sudo pacman -S --needed --noconfirm "${missing[@]}"; then
        log_success "Đã cài đặt xong các gói pacman."
      else
        log_warn "Một số gói pacman không thể cài. Kiểm tra lại kết nối mạng hoặc mirrorlist."
      fi
    else
      log_warn "Bỏ qua cài đặt gói pacman."
    fi
  else
    log_success "Profile '$target': Toàn bộ ${#pacman_pkgs[@]} gói pacman đã có sẵn."
  fi

  # 2. Gói AUR
  local missing_aur=()
  for pkg in "${aur_pkgs[@]}"; do
    pacman -Qi "$pkg" &>/dev/null || missing_aur+=("$pkg")
  done

  if [ ${#missing_aur[@]} -gt 0 ]; then
    log_info "Profile '$target': Thiếu ${#missing_aur[@]}/${#aur_pkgs[@]} gói AUR."
    log_dim "AUR thiếu: ${missing_aur[*]}"
    local aur_helper=""
    aur_helper="$(arch_get_aur_helper || true)"
    if [ -n "$aur_helper" ]; then
      log_info "Cài AUR packages qua $aur_helper..."
      if ! $aur_helper -S --needed --noconfirm "${missing_aur[@]}"; then
        log_warn "Cài đặt hàng loạt AUR gặp lỗi. Đang thử cài đặt từng gói riêng lẻ..."
        for apkg in "${missing_aur[@]}"; do
          if ! pacman -Qi "$apkg" &>/dev/null; then
            $aur_helper -S --needed --noconfirm "$apkg" || log_warn "Không thể cài gói AUR: $apkg"
          fi
        done
      fi
      log_success "Hoàn tất xử lý gói AUR."
    else
      log_warn "Thiếu AUR helper. Cài thủ công: yay -S ${missing_aur[*]}"
    fi
  else
    if [ ${#aur_pkgs[@]} -gt 0 ]; then
      log_success "Profile '$target': Toàn bộ ${#aur_pkgs[@]} gói AUR đã có sẵn."
    fi
  fi
}
