# Handoff — HP ProDesk 400 G5 SFF home lab (Debian 13, manual install)

## Focus

Bàn giao trạng thái hiện tại của máy home lab `192.168.1.56` (HP ProDesk 400 G5 SFF) và repo
`dotfiles-stow` branch `server-minimal`, để session mới tiếp tục mà không phải dựng lại context.

## Handoff reason

`user-initiated`

## Repo state

- Repo: `~/Repos/github.com/trongnghiango/dotfiles-stow`
- Branch: `server-minimal`
- HEAD: `d74c8ba` (docs(install): manual A-to-Z CLI install guide extracted from install_debian.sh)
- Dirty: `?? .tmp/` (untracked, pre-existing session scratch — không commit)

## State

Máy `192.168.1.56` đang chạy **Debian 13 (trixie) cài tay thành công** bằng
`docs/manual-install-debian.md`: UEFI, GPT (ESP 1 GiB + root ext4 222.6 GiB, **không swap**),
kernel `6.12.118+deb13-amd64`, `ssh`/`NetworkManager`/`systemd-timesyncd` active, efivarfs mount,
`firmware-realtek` + `intel-microcode` đã cài. SSH `user`/`[REDACTED]` hoạt động. Secure Boot đã tắt.
Firmware đã đặt `After Power Loss = Power On`, WoL (`Bypass Password`) và Debian đã bật
`wake-on-lan magic`. Điểm còn treo: **HP Physical Presence Interface** đang bật → mỗi khi BIOS bị
thay đổi từ OS, lần boot sau firmware hiện 4 số và bắt gõ lại; cần một lần người thật tại máy để
xác nhận, sau đó nên đặt `Physical Presence Interface = Disable`.

## Verification

Last known result: **PASS**

```bash
# repo
cd ~/Repos/github.com/trongnghiango/dotfiles-stow
bash -n install_debian.sh              # OK
./scripts/.local/bin/agent-guard       # All agent-safety checks passed

# target host (từ máy local, dùng sshpass-style askpass hoặc ssh thường)
ping -c1 192.168.1.56
ssh user@192.168.1.56 'uname -r; findmnt -no SOURCE /; free -h | sed -n 3p'
# kỳ vọng: 6.12.118+deb13-amd64 | /dev/sda2 | Swap: 0B
```

## Constraints

- **CẤM ghi BIOS từ xa** (`/sys/class/firmware-attributes/hp-bioscfg/...`): mỗi lần ghi sẽ tạo
  thay đổi cần xác nhận **Physical Presence** → lần boot sau firmware hỏi mã 4 số, máy dừng chờ người.
  Đã từng làm treo máy khi dump hàng loạt attribute → chỉ đọc/ghi từng mục, mỗi lệnh phải có `timeout`.
- Không dùng script `install_debian.sh` để cài lại máy này nữa: user chuyển sang cài tay theo
  `docs/manual-install-debian.md`.
- Không revert các fix trong `install_debian.sh` (rbind chroot, efivarfs fstab, firmware NIC,
  disk-size guard, preflight mirror/clock) — đó là các lỗi thật đã gặp.
- Không `sed -i` lên file thuộc stow package; chạy `agent-guard` trước khi kết thúc phiên.
- Máy không có ai thường trực: mọi thao tác cần người phải gom lại một lần.

## Risk context

Tier 3 (destructive/system-level): phân vùng, bootloader, NVRAM, BIOS settings trên máy thật.
Sai một bước là mất khả năng truy cập từ xa. Không có IPMI; chỉ có WoL + `After Power Loss = Power On`.

## Artifacts

- `docs/manual-install-debian.md` — cài Debian tay A→Z (nguồn chuẩn session mới nên dùng)
- `docs/homelab-prodesk-400-g5.md` — hồ sơ phần cứng + quyết định UEFI vs Legacy + khuyến nghị BIOS
- `fix-gpt.sh` — cứu hộ khi bảng GPT bị ghi đè sai (chọn "2" ở prompt HP)
- `install_debian.sh` — installer tự động (không dùng cho máy này nữa nhưng vẫn giữ làm tham chiếu)
- Commits: `226e815` (fix-gpt), `404ca97` (efivarfs), `2008b12` (preflight clock/mirror),
  `4420b79` (rbind/firmware/disk-guard), `f1ee7e8` + `d74c8ba` (docs)

## Decisions

1. **UEFI, không Legacy** — GPT, Secure Boot khả dụng, IOMMU, hỗ trợ Debian 13 tốt hơn.
2. **Secure Boot = OFF** — tránh phải ký MOK cho VFIO/DKMS/driver ngoài; đã tắt trên máy.
3. **Không swap** — chuẩn bị cho Kubernetes (kubelet `failSwapOn=true`); `ks` sẽ tạo zRAM, cần tắt nếu chạy K8s.
4. **Giữ BIOS Q08 02.30.00** (`sp156669`, 18/01/2025) — bản cuối dòng Q08, có vá CVE; hạ cấp không tăng tương thích.
5. **Cài tay thay vì script** — user yêu cầu kiểm soát trực tiếp; script gây ra quá nhiều bước can thiệp boot.
6. **Không tạo EFI entry thủ công** trên máy này nữa; để installer/firmware tự tạo `OS Boot Manager`.
   (`fix-gpt.sh` chỉ dùng khi GPT hỏng.)

## Next steps

1. (Cần người, một lần) Khi boot hiện 4 số → gõ đúng 4 số → vào `F10` → `Security` →
   `Physical Presence Interface = Disable` → Save. Sau đó không còn prompt captcha.
2. (Cần người, một lần) Rút USB Ventoy (`sdb`) khỏi máy.
3. (Remote, tùy chọn) `sudo apt install -y efibootmgr lm-sensors smartmontools`; `sensors-detect`;
   `smartctl -H /dev/sda`.
4. (Remote, tùy chọn) Clone dotfiles vào `~/.dotfiles` và chạy `ks` nếu muốn Docker/UFW/Fail2ban;
   lưu ý `ks` tạo zRAM → `swapoff -a` + xoá `/etc/systemd/zram-generator.conf` nếu chạy K8s.
5. (Phần cứng) Thay nguồn 2 dây DIY từ cổng slim-DVD bằng cáp nguồn SATA chuẩn; cân nhắc NVMe M.2 2280
   và 2×16 GB DDR4-2666 JEDEC.
6. (Tùy chọn) Nếu cần VM/passthrough: bật VT-d trong `F10` (một lần, cùng lúc với bước 1) và thêm
   drop-in `GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"`.

## Blockers

- **Physical Presence captcha** chặn boot tự động cho tới khi có người xác nhận một lần
  (`Physical Presence Interface = Enable`). Không xử lý được từ xa.
- Không có IPMI/KVM; nếu máy treo cứng (không phải tắt), WoL không cứu được — cần ngắt điện vật lý.
- Nguồn SSD qua đường DIY 5V từ cổng slim-DVD là điểm rủi ro đã gây rớt máy/`3F0` nhiều lần.
- SSD Kingston `SUV400S37/240G` có firmware lạ (`Q0526A`, serial `AA0000…`), hiệu năng thấp
  (ghi ~156 MB/s); SMART hiện sạch (0 reallocated/pending/CRC).

## Prior handoff

N/A — đây là handoff đầu tiên (`docs/handoff/` được tạo trong session này).

## Suggested skills

- `ka-handoff` — tiếp tục chuỗi handoff nếu session mới kết thúc giữa việc.
- `ka-ops` — nếu chuyển sang Docker/K8s trên máy này.
- `ka-db-schema` / `ka-be` — chỉ khi bắt đầu dự án ứng dụng, không liên quan hạ tầng hiện tại.
