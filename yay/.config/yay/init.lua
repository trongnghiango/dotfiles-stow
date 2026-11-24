-- ~/.config/yay/init.lua — cấu hình Lua cho yay v13 (quản lý trong dotfiles)
--
-- Mục đích: chặn yay nâng cấp AUR package davinci-resolve.
--
-- Lý do: PKGBUILD davinci-resolve 21.2 dùng source
--   file://DaVinci_Resolve_21.2_Linux.zip
-- tức là phải tự tải file cài đặt của Blackmagic vào thư mục build.
-- Nếu chưa có file, makepkg fail -> omarchy-update-aur-pkgs
-- (chạy `yay -Sua --noconfirm --cleanafter ... || exit 1`) báo lỗi
-- và huỷ luôn phần update AUR.
--
-- Hook này chỉ áp dụng cho thao tác nâng cấp (yay -Syu / -Sua).
-- Khi muốn nâng cấp thật: tải đúng file zip vào
--   ~/.cache/yay/davinci-resolve/
-- rồi chạy `yay -S davinci-resolve` (cài tường minh) — hook không chặn.

yay.create_autocmd("UpgradeSelect", {
  desc = "hold davinci-resolve until the manual DaVinci zip is provided",
  callback = function(event)
    local exclude = {}
    for _, pkg in ipairs(event.data.upgrades) do
      if pkg.name == "davinci-resolve" or pkg.base == "davinci-resolve" then
        exclude[#exclude + 1] = pkg.name
        yay.log.info(string.format(
          "Holding AUR upgrade: %s %s -> %s",
          pkg.name, pkg.local_version, pkg.remote_version
        ))
      end
    end
    if #exclude > 0 then
      return { exclude = exclude, skip_menu = false }
    end
    return nil
  end,
})
