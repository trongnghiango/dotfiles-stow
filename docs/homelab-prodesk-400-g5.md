# Home lab: HP ProDesk 400 G5 SFF — cài Debian chính thống, chọn UEFI/Legacy, cấu hình BIOS tối ưu

> Tài liệu nghiên cứu, dựa trên hồ sơ phần cứng đọc trực tiếp từ máy (`dmidecode`, `lspci`, `lscpu`, `dmesg`).
> Ngày lập: 2026-11-26.

---

## 1. Hồ sơ phần cứng (thực tế đọc từ máy)

| Thành phần | Giá trị |
|---|---|
| Máy | **HP ProDesk 400 G5 SFF** (SKU 2ZX70AV, serial JPH913VRZZ) — dòng SFF 2018 |
| Mainboard | HP **83F2**, KBC 07.D4.00 |
| BIOS | **Q08 Ver. 02.30.00**, 30/12/2024, ROM 16 MB (SoftPaq `sp156669`, phát hành 18/01/2025) |
| CPU | Intel **Core i5-8500** (Coffee Lake, 6C/6T, 3.0–4.1 GHz, UHD 630) |
| Chipset | Intel **B360** (Cannon Lake PCH) |
| RAM | 2 × 8 GB DDR4-2666 (Corsair `CMK16GX4M2A2666C16`), đang chạy **2133 MT/s**, tối đa 32 GB / 2 khe |
| Lưu trữ | SATA AHCI 6 cổng (hiện dùng `ata2`); **1 × M.2 2280/2230 PCIe x4 (NVMe)** + 1 × M.2 2230 (WLAN) |
| NIC | Realtek **RTL8111/8168** (driver `r8169`, cần `firmware-realtek` cho một số bản) |
| IOMMU | Có `DMAR` → **VT-d khả dụng** (cần bật trong BIOS) |
| TPM | Có (`/sys/class/tpm/tpm0`) |
| Secure Boot | Đang **BẬT**, keys đầy đủ (PK 1232B, KEK 2794B, db 5827B) |
| Ổ hiện tại | Kingston SUV400S37/240G (SATA) — controller/firmware lạ, ghi ~156 MB/s, đọc file ~430 MB/s |

**Kết luận về "đời máy":** nền tảng Intel 300-series, CPU thế hệ 8 (2018). Debian 13 (trixie, kernel 6.12) hỗ trợ đầy đủ, không cần driver đặc biệt ngoài `intel-microcode` + `firmware-realtek`. Đây là phần cứng "chuẩn mực", không phải hàng khó cài.

---

## 2. Legacy BIOS hay UEFI?

**Chọn UEFI.** Lý do cụ thể với máy này:

| Tiêu chí | UEFI | Legacy (CSM) |
|---|---|---|
| Phân vùng | GPT, không giới hạn 2 TB, nhiều phân vùng | MBR, 4 phân vùng chính |
| Secure Boot | Có (shim + GRUB ký của Debian) | Không |
| IOMMU/VT-d cho VM (VFIO passthrough) | Dùng bình thường | Dùng được nhưng firmware path cũ hơn |
| Debian 13 | Đường mặc định, được test nhiều nhất | Vẫn cài được nhưng ít ưu tiên hơn |
| Cập nhật firmware / đo lường boot | Hỗ trợ (fwupd, TPM measured boot) | Kém |

Chỉ nên dùng Legacy khi cần boot một thiết bị/OS rất cũ hoặc phần mềm cứu hộ MBR-only. Với home lab dùng Docker/K8s/KVM: **UEFI thuần, tắt CSM/Legacy Support**.

### Secure Boot: nên bật hay tắt?

- **Bật** nếu bạn chỉ dùng module/kernel có sẵn trong Debian. Debian có shim ký Microsoft + GRUB ký Debian → cài và boot được ngay, không cần MOK.
- **Tắt** nếu bạn sẽ chạy: VFIO (kèm module tự build), ZFS trên Debian (DKMS), kernel tự compile, driver ngoài (r8168-dkms, NVIDIA). Khi đó phải `mokutil --import` và ký module — thêm việc, dễ hỏng sau mỗi lần nâng kernel.

**Khuyến nghị cho home lab của bạn: UEFI + Secure Boot TẮT**, vì bạn sẽ thử nhiều thứ (VFIO cho GPU passthrough, driver Realtek thay thế, có thể ZFS). Bật lại bất cứ lúc nào nếu muốn.

---

## 3. Cài Debian "chính thống" (đường chuẩn của Debian)

1. Tải **Debian 13 netinst amd64** từ trang chính thức: `https://www.debian.org/download` (file `debian-13.x.0-amd64-netinst.iso`).
2. Xác thực ISO (bắt buộc, tránh ISO hỏng/giả):
   ```bash
   sha256sum debian-13.*-amd64-netinst.iso      # so với SHA256SUMS trên debian.org
   gpg --verify SHA256SUMS.sign SHA256SUMS      # key Debian
   ```
3. Ghi ra USB: `sudo dd if=debian-13.*-amd64-netinst.iso of=/dev/sdX bs=4M status=progress oflag=sync`
   (hoặc Ventoy như bạn đang dùng — vẫn là ISO chính thức, chỉ khác cách boot).
4. Boot ở chế độ **UEFI** (menu boot của HP: `F9`), chọn `UEFI: <USB>`.
5. Trong installer:
   - Language/locale: `en_US.UTF-8` (hoặc `vi_VN`), timezone `Asia/Ho_Chi_Minh`.
   - Network: DHCP (Realtek RTL8111 được kernel hỗ trợ sẵn).
   - User: tạo user thường, đặt mật khẩu; root dùng sudo.
   - Phân vùng: **Guided – use entire disk** (ESP ~512 MB–1 GB + root ext4). Nếu chạy K8s/kubelet: **không tạo swap** (hoặc dùng zram). Swap file/partition đều làm kubelet từ chối (`failSwapOn=true`).
   - Software: bỏ hết desktop; chọn `SSH server` + `standard system utilities`.
6. Sau khi cài, thêm `non-free-firmware` vào `sources.list` rồi cài:
   ```bash
   sudo apt install intel-microcode firmware-realtek lm-sensors smartmontools
   ```
7. Bật IOMMU nếu dùng VM/passthrough: thêm `intel_iommu=on iommu=pt` vào `GRUB_CMDLINE_LINUX_DEFAULT`, rồi `sudo update-grub && reboot`.

Đó là toàn bộ "đường chính thống": netinst chính thức + UEFI + GPT + ext4, không cần script nào.

---

## 4. Firmware: có nên hạ BIOS để "tương thích hơn"?

**Không nên. Giữ Q08 02.30.00.**

- Đây là bản **mới nhất và cuối** của dòng Q08 cho ProDesk 400 G5 SFF (`sp156669`, 18/01/2025), có vá CVE-2024-38307, CVE-2024-26021, CVE-2024-30211, CVE-2024-36293.
- Nền tảng Coffee Lake/B360 với Debian 13 không có vấn đề tương thích nào cần hạ BIOS. Hạ xuống 02.29/02.21 chỉ mất bản vá, không thêm khả năng.
- Chỉ hạ khi có lỗi cụ thể mà HP xác nhận do bản mới (HP có setting `BIOS Rollback Policy` trong BIOS setup để cho phép/hạn chế rollback).

Cách nâng/hạ nếu cần (đường HP hỗ trợ):
1. Tải SoftPaq từ `ftp.hp.com` (ví dụ `sp156669.exe`), giải nén lấy file `.bin`.
2. Copy `.bin` vào USB **FAT32**, thư mục `/HP/BIOS/Newest/`.
3. `F10` → `Update System BIOS` → chọn file. Không dùng file `.bin` tải từ diễn đàn (dump chip SPI) — nạp sai là brick.

Kiểm tra xem HP có đẩy firmware lên LVFS cho model này không (thường desktop HP **không** có): `fwupdmgr get-devices`, `fwupdmgr get-updates`.

---

## 5. Cấu hình BIOS tối ưu cho home lab

| Mục (F10) | Đặt | Vì sao |
|---|---|---|
| Advanced → **Virtualization Technology (VT-x)** | On | KVM/Docker |
| Advanced → **VT-d / IOMMU** | On | passthrough GPU/NIC cho VM, `intel_iommu=on` |
| Security → **Secure Boot** | **Off** (nếu VFIO/ZFS/driver ngoài) | tránh phải ký MOK mỗi lần đổi kernel |
| Advanced → **Legacy Support / CSM** | Off | UEFI thuần, GPT |
| Advanced → Power-On Options → **After Power Loss** | **Power On** | mất điện có lại là tự bật — bắt buộc cho máy không người |
| Advanced → Power-On Options → **WoL / S5 Wake** | On (nếu cần bật từ xa) | cứu hộ từ xa; tắt "S5 Maximum Power Savings" để NIC còn điện |
| Advanced → **Boot Order** | ổ trong (OS Boot Manager) trước; **Network/PXE: Off** | bỏ 30 s chờ PXE, không bị PXE cướp boot |
| Advanced → **Fast Boot** | On | POST nhanh |
| Storage → **SATA Emulation** | AHCI | chuẩn cho Linux, TRIM |
| Built-In Device Options | tắt Serial/Parallel port nếu không dùng | giảm tài nguyên, gọn log |
| Security → TPM | On (2.0) | LUKS + measured boot nếu cần; không ảnh hưởng K8s |
| Advanced → **BIOS Rollback Policy** | theo mặc định | chỉ đổi khi cần hạ firmware |
| Fan/thermal | để Auto | SFF nhỏ, đừng ép fan thấp |

Lưu ý: các mục trên đọc/ghi được **từ Linux** qua `/sys/class/firmware-attributes/hp-bioscfg/attributes/` (kernel `hp_bioscfg`), nên có thể cấu hình lại từ xa — nhưng đừng dump hàng loạt (đã từng làm treo máy); đọc/ghi từng mục một, mỗi lệnh có timeout.

---

## 6. Tối ưu hệ thống sau cài (home lab)

### Kernel / sysctl
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
```
- `iommu=pt` giảm overhead khi không passthrough thiết bị.
- Nếu chạy K8s: `swapoff -a`, không cấu hình zram; bật `overlay`, `br_netfilter`, `net.ipv4.ip_forward=1`, `net.bridge.bridge-nf-call-iptables=1`.
- Nếu chạy nhiều VM: `vm.swappiness` thấp (10–20) hoặc 0 khi không swap; `vm.overcommit_memory=1` chỉ khi cần (Redis/ML), mặc định để 0.

### Lưu trữ
- SSD hiện tại là hàng controller lạ, ghi ~156 MB/s. **Nâng cấp NVMe M.2 2280** (khe PCIe x4 sẵn có) là cải thiện lớn nhất: 1 TB NVMe Gen3 (~2–3 GB/s) làm ổ OS + container layer.
- Giữ SSD Kingston làm ổ backup/log hoặc thay hẳn.
- Bật `fstrim.timer` (SSD SATA) và `mq-deadline` cho SATA, `none` cho NVMe.

### RAM
- CPU hỗ trợ DDR4-2666 nhưng HP không có XMP; kit Corsair đang chạy 2133. Muốn 2666 phải dùng module JEDEC 2666 (không XMP).
- 16 GB đủ cho vài VM nhỏ; **2 × 16 GB (32 GB)** là mức tối đa, đáng nâng nếu chạy K8s + VM.

### Mạng
- `firmware-realtek` cho RTL8111; nếu gặp lỗi link/flap, thay bằng `r8168-dkms` (cần Secure Boot off).
- MTU 1500 mặc định; nếu dùng nhiều container, bật BBR + `fq` (đã có trong `ks`).

### Nhiệt & nguồn
- SFF nhỏ, i5-8500 tản nhiệt khiêm tốn: giữ fan Auto, vệ sinh tản mỗi 6–12 tháng, theo dõi `sensors`.
- **Bỏ nguồn 2 dây DIY từ cổng slim-DVD**: dùng cáp nguồn SATA chuẩn từ PSU (hoặc splitter Molex→SATA). Nguồn chập chờn là nguyên nhân các lần máy rớt/`3F0`/treo bất thường.
- Đặt `After Power Loss = Power On` + WoL để không cần người bấm nút.

---

## 7. Checklist triển khai

- [ ] Tải + verify ISO netinst Debian 13
- [ ] BIOS: UEFI only, VT-x + VT-d, Secure Boot off, After Power Loss = Power On, WoL on, PXE off, AHCI
- [ ] Cài bằng installer chính thức: GPT + ext4, **không swap** (nếu K8s), SSH server
- [ ] `intel-microcode`, `firmware-realtek`, `lm-sensors`, `smartmontools`
- [ ] `intel_iommu=on iommu=pt` nếu dùng VM
- [ ] Nâng cấp NVMe + 32 GB RAM (tuỳ ngân sách)
- [ ] Thay nguồn DIY bằng cáp SATA chuẩn
- [ ] Kiểm tra: `systemctl status ssh`, `sensors`, `smartctl -a`, `dmesg | grep -i iommu`

---

## Nguồn tham chiếu

- HP Firmware Pack (Q08) 02.30.00 — `sp156669`: <https://ftp.hp.com/pub/softpaq/sp156501-157000/sp156669.html>
- HP ProDesk 400 G5 SFF — cấu hình khe M.2/SATA (datasheet): <https://objects.icecat.biz/objects/mmo_57432357_1581434919_8077_24753.pdf>
- Debian 13 Installation Guide (amd64): <https://www.debian.org/releases/trixie/amd64/install.en.txt>
- Debian 13 tải ISO + checksum: <https://www.debian.org/download>
