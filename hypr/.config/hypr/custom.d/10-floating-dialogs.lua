-- ==============================================================================
-- HYPRLAND FLOATING DIALOGS & FILE CHOOSERS
-- ==============================================================================
-- File: ~/.config/hypr/custom.d/10-floating-dialogs.lua
-- Mục đích: Đảm bảo tất cả các hộp thoại Open/Save file, folder, modal dialog
--           (Tauri/bun-player, GTK, Qt, Portals) luôn nổi (floating) và căn giữa,
--           không bị ép vào tiling hoặc chiếm fullscreen làm gián đoạn workspace.
-- ==============================================================================

-- 1. Tất cả cửa sổ modal con của ứng dụng
o.window({ modal = true }, {
  tag = "+floating-window",
})

-- 2. Hộp thoại File/Folder Chooser theo tiêu đề (Tất cả ứng dụng kể cả Tauri, Electron, GTK, Qt)
o.window(
  {
    title = "^(Open.*Files?|Open [F|f]older.*|Open [D|d]irectory.*|Open|Save.*Files?|Save.*As.*|Save.*Image.*|Save|Select [F|f]older.*|Select.*Files?|Select a [F|f]ile.*|Choose [F|f]older.*|Choose.*Files?|Choose a [F|f]ile.*|All Files.*|File Upload.*|.*wants to (open|save).*)$",
  },
  {
    tag = "+floating-window",
  }
)

-- 3. Các tiến trình Portal, Dialog helper và Authentication agent
o.window(
  "^(xdg-desktop-portal-.*|org\\.freedesktop\\.impl\\.portal.*|zenity|yad|kdialog|file-roller|org\\.gnome\\.FileRoller|polkit-.*-authentication-agent.*)$",
  {
    tag = "+floating-window",
  }
)
