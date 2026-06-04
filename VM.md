# Virt-install Command Templates

Note: Copy the ISO to `/tmp` before running the command to avoid permission issues.

## Arch Linux
```shell
sudo virt-install --connect qemu:///system --name archvm --memory 6144 --vcpus 2 --cpu host-passthrough --disk size=50,format=qcow2,bus=virtio --network network=default,model=virtio --os-variant archlinux --cdrom /tmp/archlinux-x86_64.iso --graphics spice,listen=none --video virtio --channel spicevmc --boot uefi --check path_in_use=off,disk_size=off
```

## Void Linux
```shell
sudo virt-install --connect qemu:///system --name void --memory 6144 --vcpus 2 --cpu host-passthrough --disk size=50,format=qcow2,bus=virtio --network network=default,model=virtio --os-variant voidlinux --cdrom /tmp/void-live-x86_64-20250202-base.iso --graphics spice,listen=none --video virtio --channel spicevmc --boot uefi --check path_in_use=off,disk_size=off
```
