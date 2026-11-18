# Prompt nhận bàn giao cho Session Mới

---

## 📋 COPY PASTE PROMPT NÀY VÀO SESSION MỚI

> **Bạn là Principal Linux Systems Engineer. Nhận bàn giao hệ thống dotfiles-stow tại `/home/ka/Repos/github.com/trongnghiango/dotfiles-stow`.**
>
> **Context:** Arch Linux + DWM/X11 + Stow cho sinh viên CS (ThinkPad X230/T480). Tất cả Phases 0-4 đã hoàn thành.
>
> **Branch:** `phase4-bulletproof-updates` (commit `876ee95`)
> **Tag rollback:** `pre-phase4` (và `pre-phase3/2/1/0`)
>
> **Đã hoàn thành:**
> - **Phase 4 Core:** Bulletproof Update System (`safe-pacman`, `ka-update`, `pacman-hold`, `ka-health`, Snapper hooks)
> - **Phase 4 Integration:** ISO profile `iso-profile/kaos-cs/` (46 files, Btrfs subvolumes, auto-installer, first-boot `ka-setup all`) + `setup_bulletproof_updates()` trong `ka-setup`
> - **Phase 0 Security:** TOCTOU fixes, `eval` RCE removed, shortcuts, xcape, Fcitx5 conflict
> - **Phase 1 Reliability:** `safe-pacman`, xinitrc cleanup, hardware stow, DWM mic_toggle, dwmblocks rename
> - **Phase 2 Architecture:** Relative theme symlink, host overlay, `/etc` backup + Btrfs snapshot, stow validation
> - **Phase 3 Dev Env (Minimal):** LSP verified, Neovide guarded
>
> **Files tham khảo:**
> - `HANDOFF_PHASE_FINAL.md` — Tổng hợp hoàn chỉnh
> - `HANDOFF_PHASE4.md` — Chi tiết Phase 4
> - `OPTIMIZATION_PLAN.md` — Roadmap có command/verify/rollback
> - `AUDIT_REPORT.md` — Source of truth (1200+ lines, line-traceable)
>
> **Quick start:**
> ```bash
> cd /home/ka/Repos/github.com/trongnghiango/dotfiles-stow
> git checkout phase4-bulletproof-updates
> ./verify_all.sh  # All ✅
>
> # Build ISO (cần máy thật/VM có KVM)
> cd iso-profile/kaos-cs
> sudo mkarchiso -v -w /tmp/build -o /out .
> qemu-system-x86_64 -m 4G -enable-kvm -cdrom /out/KaOS-CS-*.iso
> ```
>
> **Nhiệm vụ tiếp theo:** Build & test ISO trên máy thật, validate rollback workflow end-to-end.

---

## 🎯 Prompt rút gọn (nếu context window nhỏ)

> **Nhận bàn giao dotfiles-stow (Arch + DWM + Stow, ThinkPad X230/T480). Branch `phase4-bulletproof-updates`, commit `876ee95`. Đã hoàn thành Phases 0-4: Bulletproof Update System (safe-pacman, ka-update, pacman-hold, ka-health, Snapper hooks), ISO profile KaOS-CS (Btrfs subvolumes, auto-installer), P0 security fixes, reliability & architecture hardening. Xem `HANDOFF_PHASE_FINAL.md` để chi tiết. Next: Build ISO trên máy có KVM, test rollback.**

---

## ✅ Checklist xác nhận bàn giao thành công

Sau khi paste prompt, session mới nên chạy:

```bash
cd /home/ka/Repos/github.com/trongnghiango/dotfiles-stow
git checkout phase4-bulletproof-updates
./verify_all.sh
```

**Output mong đợi:** Tất cả các check Phase 0-3 hiển thị `✅`