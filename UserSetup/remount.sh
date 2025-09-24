#!/bin/bash
# remount.sh
# Robust remount for Disk9 + Disk10 with exfat-fuse and root:sharedgroup

set -euo pipefail

GROUP="sharedgroup"

DISK9_DEV="/dev/mapper/bitlk-2066"
DISK10_DEV="/dev/mapper/bitlk-2082"

DISK9_MNT="/mnt/Expansion/Disk9"
DISK10_MNT="/mnt/Expansion/Disk10"

echo ">>> Disabling udisks2 (desktop automount)..."
systemctl stop udisks2.service || true
systemctl disable udisks2.service || true

force_unmount() {
    local DEV="$1"
    local MNT="$2"
    
    echo ">>> Checking and unmounting $DEV..."
    
    # Unmount known paths
    umount -f "$MNT" 2>/dev/null || true
    umount -f "$DEV" 2>/dev/null || true
    
    # Unmount from /media/*
    for p in /media/*/*; do
        [ -d "$p" ] && umount -f "$p" 2>/dev/null || true
    done
    
    # Check /proc/mounts
    if grep -q "$DEV" /proc/mounts; then
        echo "Device $DEV still mounted (ghost). Forcing dmsetup remove..."
        dmsetup remove "$DEV" || true
    fi
}

# Ensure mount points exist
mkdir -p "$DISK9_MNT" "$DISK10_MNT"

# Kill kernel exfat if loaded
if lsmod | grep -q "^exfat"; then
    echo ">>> Removing kernel exfat module..."
    modprobe -r exfat || true
fi

# Unmount both disks
force_unmount "$DISK9_DEV" "$DISK9_MNT"
force_unmount "$DISK10_DEV" "$DISK10_MNT"

# Remount with exfat-fuse
echo ">>> Remounting Disk9..."
mount -t exfat-fuse -o defaults,uid=0,gid=$GROUP,umask=007 "$DISK9_DEV" "$DISK9_MNT"

echo ">>> Remounting Disk10..."
mount -t exfat-fuse -o defaults,uid=0,gid=$GROUP,umask=007 "$DISK10_DEV" "$DISK10_MNT"

# Update fstab entries
echo ">>> Updating /etc/fstab..."
for DEV in "$DISK9_DEV" "$DISK10_DEV"; do
    if [ "$DEV" == "$DISK9_DEV" ]; then
        MNT="$DISK9_MNT"
    else
        MNT="$DISK10_MNT"
    fi
    sed -i "\|$MNT|d" /etc/fstab
    echo "$DEV  $MNT  exfat-fuse  defaults,uid=0,gid=$GROUP,umask=007  0  0" >> /etc/fstab
done

echo ">>> Final permissions:"
ls -ld "$DISK9_MNT" "$DISK10_MNT"

echo "=== Done! Both disks are mounted as root:sharedgroup (770). ==="
