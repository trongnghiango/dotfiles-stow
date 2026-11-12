# HANDOFF — Phase 4: Bulletproof Update System (Arch-native)

**Date:** 2025-11-12  
**Branch:** `phase4-bulletproof-updates` (commit `39dd69e`)  
**Tag:** `pre-phase4` (rollback point)  
**Target:** Arch Linux + Stow + DWM/X11 (ThinkPad X230/T480)

---

## 📍 CURRENT STATE

| Item | Status |
|------|--------|
| **Phase 0-3** | ✅ Complete, committed (`34ed94d`) |
| **Phase 4 Core Tools** | ✅ Complete, committed (`39dd69e`) |
| **Phase 4 Integration** | ⬜ **Remaining** (2 tasks) |
| **Git branch** | `phase4-bulletproof-updates` |
| **Safety tag** | `pre-phase4` |

---

## ✅ WHAT'S DONE — Phase 4 Core Tools

### 4.1 Snapper Auto-Snapshots (Pacman Hooks)
```
system-config/etc/pacman.d/hooks/
├── 99-snapper-pre.hook      # Pre-transaction snapshot
├── 99-snapper-post.hook     # Post-transaction (linked to pre)
└── 99-grub-btrfs.hook       # Update GRUB-Btrfs boot menu
```

### 4.2 Helper Scripts
| Script | Purpose |
|--------|---------|
| `scripts/.local/bin/snapper-pacman-wrapper` | Pre/post wrapper called by hooks |
| `scripts/.local/bin/snapper-setup` | Initial config with cleanup policy (timeline + number limits) |

### 4.3 safe-pacman (Enhanced)
```
scripts/.local/bin/safe-pacman
```
- PID 1 scope (`systemd-run --scope`) — survives systemd re-exec
- Sudo keepalive — no password prompt mid-transaction
- Full session logging via `script` command
- **Pre-flight checks:** disk space, keyring, mirror reachability, needrestart
- **Post-update verification:** GRUB config, critical binaries, systemd state, .pacnew/.pacsave

### 4.4 ka-update — High-Level Update Manager
```
scripts/.local/bin/ka-update
```
| Command | Action |
|---------|--------|
| `ka-update check` | Show official/AUR/Flatpak updates |
| `ka-update download` | Download only (`-Syuw`) |
| `ka-update apply` | Full upgrade with kernel detection → auto `mkinitcpio -P` |
| `ka-update aur` | Update AUR packages (yay/paru) |
| `ka-update flatpak` | Update Flatpaks |
| `ka-update rollback <num>` | Snapper rollback to snapshot |
| `ka-update list-snapshots` | List all snapper snapshots |
| `ka-update status` | Full dashboard |

### 4.5 pacman-hold — Package Hold Manager
```
scripts/.local/bin/pacman-hold
```
- `add/remove/list/clear` packages in `IgnorePkg`
- `group add/remove/list` groups in `IgnoreGroup`
- Shows available updates for held packages
- Backups to `/var/backups/pacman-hold/` before changes

### 4.6 ka-health — System Health Dashboard
```
scripts/.local/bin/ka-health [--quick] [--json]
```
Checks: updates, disk, snapper, services, pacman, hardware (ThinkPad battery/thermal), boot, security, dotfiles

---

## ⬜ WHAT REMAINS — Phase 4 Integration

### Task 4.6: archiso Profile — Custom KaOS-CS ISO
**Location:** `iso-profile/kaos-cs/` (to create)

**Requirements:**
- Base: `archiso` + `arch-install-scripts`
- Auto-partition: Btrfs on root with subvolumes (`@`, `@home`, `@snapshots`, `@log`, `@pkg`)
- Snapper pre-configured (configs for root + home)
- grub-btrfs installed + configured
- Pacman hooks deployed from `system-config/etc/pacman.d/hooks/`
- Package list: base + KaOS-CS packages (from `pkgs/arch.csv` tier 1-2)
- Post-install: auto-run `ka-setup all` (or minimal `ka-setup pkgs core && ka-setup stow`)
- Target: ThinkPad X230/T480 (include `intel-ucode`, `thermald`, `tlp`, `acpi_call`, `tp_smapi`)

**Reference:** Current `install_arch.sh` (in repo) has partitioning logic — adapt for archiso.

### Task 4.7: ka-setup Integration
**File:** `scripts/.local/bin/ka-setup`

**Add to `setup_pkgs()` or new `setup_bulletproof_updates()`:**
```bash
# 1. Install core packages
pacman -S --needed snapper grub-btrfs snap-pac reflector needrestart

# 2. Deploy pacman hooks
cp -r "$DOTFILES_DIR/system-config/etc/pacman.d/hooks/" /etc/pacman.d/hooks/

# 3. Configure snapper
snapper-setup  # (script already created)

# 4. Enable timers
systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
systemctl enable --now grub-btrfsd.path  # or use hook

# 5. Default holds (detect hardware)
pacman-hold add linux-lts
lspci | grep -i nvidia && pacman-hold add nvidia nvidia-utils nvidia-settings

# 6. Configure reflector (weekly mirror refresh)
systemctl enable --now reflector.timer
```

---

## 🔧 KEY FILES TO KNOW

| Category | Files |
|----------|-------|
| **Pacman hooks** | `system-config/etc/pacman.d/hooks/*.hook` |
| **Core scripts** | `scripts/.local/bin/{safe-pacman,ka-update,pacman-hold,ka-health,snapper-pacman-wrapper,snapper-setup}` |
| **Integration target** | `scripts/.local/bin/ka-setup` |
| **ISO profile (TODO)** | `iso-profile/kaos-cs/` |
| **Package lists** | `pkgs/arch.csv`, `pkgs/debian.csv` |
| **Hardware profiles** | `hardware/.config/hardware/profiles/` |
| **Rollback tag** | `git tag pre-phase4` |

---

## 🧪 TEST PLAN (for next session)

```bash
# 1. Build ISO
cd iso-profile/kaos-cs
mkarchiso -v -w /tmp/build -o /out .

# 2. Test in VM
qemu-system-x86_64 -m 4G -enable-kvm -cdrom /out/KaOS-CS-*.iso

# 3. Verify post-install:
#    - snapper -c root list  (should show initial snapshot)
#    - ka-update check       (should work)
#    - ka-health             (all green)
#    - safe-pacman -Syu      (pre-flight + logging)
#    - pacman-hold list      (shows linux-lts)

# 4. Test rollback:
#    - Install a package
#    - ka-update rollback <pre-snapshot>
#    - Reboot → verify package gone
```

---

## ⚠️ KNOWN GOTCHAS

1. **Snapper needs Btrfs subvolumes** — ISO must create `@snapshots` subvolume and mount at `/.snapshots`
2. **grub-btrfs** — Use `grub-btrfsd` daemon (path unit) or hook; daemon is more reliable for menu updates
3. **snap-pac** — Alternative to hooks (pacman plugin), but hooks are simpler and already written
4. **ThinkPad X230** — Needs `acpi_call` + `tp_smapi` for battery thresholds; T480 uses native `charge_control_end_threshold`
5. **AUR helper** — `yay` preferred (in `pkgs/arch.csv`); `paru` as fallback
6. **safe-pacman logging** — Uses `script` command; ensure `util-linux` installed (base)

---

## 🚀 QUICK START FOR NEXT SESSION

```bash
cd /home/ka/Repos/github.com/trongnghiango/dotfiles-stow
git checkout phase4-bulletproof-updates

# 1. Create archiso profile (reference: /usr/share/archiso/configs/releng/)
mkdir -p iso-profile/kaos-cs/{airootfs,profiledef.sh,packages.x86_64,syslinux,efiboot}

# 2. Add packages to packages.x86_64 (from pkgs/arch.csv tier 1-2)

# 3. Write profiledef.sh with Btrfs subvolume layout

# 4. Add install script to airootfs/root/install.sh → runs ka-setup

# 5. Update ka-setup with setup_bulletproof_updates()

# 6. Build & test
```

---

## 📞 CONTACT / CONTEXT

All context preserved in:
- `AUDIT_REPORT.md` — Full audit (source of truth)
- `OPTIMIZATION_PLAN.md` — Original 19-task plan
- `HANDOFF.md` — Previous session handoff (Phase 0-3)
- `verify_all.sh` — Verification script (updated for Phase 0-3)

**Next session should start with:** Create `iso-profile/kaos-cs/` based on `archiso` releng profile.

---

*Generated by Principal Linux Systems Engineer — Phase 4 core tools complete.*