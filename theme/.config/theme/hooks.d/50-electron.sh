#!/usr/bin/env bash
# ==============================================================================
# Hook 50: Electron, VS Code & Editor Theme Synchronization
# Triết lý: Đồng bộ tự động theme cho VS Code / Code - OSS, Obsidian, và Electron apps
# ==============================================================================
set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
CURRENT_LINK="$THEME_DIR/colors/current.conf"

if [ ! -f "$CURRENT_LINK" ]; then
    exit 0
fi

# 1. Nạp thông tin theme hiện tại
set -a
# shellcheck disable=SC1090
source "$CURRENT_LINK"
THEME_NAME=$(basename "$(readlink -f "$CURRENT_LINK")" .conf)
THEME_MODE="${MODE:-dark}"
set +a

# 2. Đồng bộ VS Code / Code - OSS / VSCodium
python3 - << 'PYEOF'
import os, sys, re, json

theme_name = os.environ.get("THEME_NAME", "gruvbox-dark")
theme_mode = os.environ.get("THEME_MODE", "dark")

# Kiểm tra các extension theme đã cài đặt
ext_dirs = [
    os.path.expanduser("~/.vscode-oss/extensions"),
    os.path.expanduser("~/.vscode/extensions"),
    os.path.expanduser("~/.vscode-codium/extensions")
]
installed_exts = set()
for ed in ext_dirs:
    if os.path.isdir(ed):
        try:
            for entry in os.listdir(ed):
                installed_exts.add(entry.lower())
        except Exception:
            pass

def has_ext(keyword):
    return any(keyword.lower() in ext for ext in installed_exts)

# Ánh xạ theme sang VS Code
if theme_mode == "light":
    if has_ext("gruvbox"):
        chosen_theme = "Gruvbox Light Soft"
    elif has_ext("catppuccin"):
        chosen_theme = "Catppuccin Latte"
    else:
        chosen_theme = "Solarized Light"
else:
    if theme_name == "gruvbox-dark" and has_ext("gruvbox"):
        chosen_theme = "Gruvbox Dark Medium"
    elif theme_name == "catppuccin-mocha" and has_ext("catppuccin"):
        chosen_theme = "Catppuccin Mocha"
    elif theme_name == "nord" and has_ext("nord"):
        chosen_theme = "Nord"
    else:
        chosen_theme = "Default Dark Modern"

# Danh sách các thư mục cấu hình VS Code
vscode_dirs = [
    os.path.expanduser("~/.config/Code - OSS/User"),
    os.path.expanduser("~/.config/Code/User"),
    os.path.expanduser("~/.config/VSCodium/User")
]

for vd in vscode_dirs:
    settings_path = os.path.join(vd, "settings.json")
    if os.path.isfile(settings_path):
        try:
            with open(settings_path, "r", encoding="utf-8") as f:
                content = f.read()

            lines = content.splitlines(keepends=True)
            replaced = False
            for i, line in enumerate(lines):
                if '"workbench.colorTheme"' in line:
                    indent = line[:len(line) - len(line.lstrip())]
                    has_comma = line.rstrip().endswith(",")
                    comma_str = "," if has_comma else ""
                    lines[i] = f'{indent}"workbench.colorTheme": "{chosen_theme}"{comma_str}\n'
                    replaced = True
                    break

            if not replaced:
                idx = content.rfind("}")
                if idx != -1:
                    prefix = content[:idx].rstrip()
                    comma = "," if not prefix.endswith(",") and not prefix.endswith("{") else ""
                    new_content = f'{prefix}{comma}\n    "workbench.colorTheme": "{chosen_theme}"\n' + content[idx:]
                else:
                    new_content = content
            else:
                new_content = "".join(lines)

            if new_content != content:
                with open(settings_path, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print(f"  [vscode] Updated {os.path.basename(vd)}: {chosen_theme}")
        except Exception as e:
            print(f"  [vscode] Error updating {settings_path}: {e}")

# 3. Đồng bộ Obsidian (nếu có vaults)
obsidian_config = os.path.expanduser("~/.config/obsidian/obsidian.json")
if os.path.isfile(obsidian_config):
    try:
        with open(obsidian_config, "r", encoding="utf-8") as f:
            data = json.load(f)
        vaults = data.get("vaults", {})
        for vid, vinfo in vaults.items():
            vpath = vinfo.get("path")
            if vpath and os.path.isdir(vpath):
                app_json = os.path.join(vpath, ".obsidian", "appearance.json")
                if os.path.isfile(app_json):
                    with open(app_json, "r", encoding="utf-8") as af:
                        app_data = json.load(af)
                    app_data["base"] = theme_mode
                    with open(app_json, "w", encoding="utf-8") as af:
                        json.dump(app_data, af, indent=2)
                    print(f"  [obsidian] Updated vault at {vpath}: {theme_mode}")
    except Exception as e:
        print(f"  [obsidian] Error: {e}")
PYEOF
