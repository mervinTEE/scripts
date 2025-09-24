#!/bin/bash
# mount_shared_expansions.sh
# Usage:
#   sudo bash mount_shared_expansions.sh
#
# Mounts unlocked BitLocker drives under /mnt/Expansion/*
# with group permissions and updates /etc/fstab.

set -euo pipefail

ADMIN="admin"
GROUP="sharedgroup"

# Ensure group exists
if ! getent group "$GROUP" >/dev/null; then
    echo "Creating group $GROUP..."
    groupadd "$GROUP"
fi
usermod -aG "$GROUP" "$ADMIN"
usermod -aG "$GROUP" sharedpc

DEVICES=$(ls /dev/mapper/bitlk-* 2>/dev/null || true)

if [ -z "$DEVICES" ]; then
    echo "No /dev/mapper/bitlk-* devices found. Unlock drives first with cryptsetup."
    exit 1
fi

DISK_NUM=9
for DEV in $DEVICES; do
    MNT="/mnt/Expansion/Disk${DISK_NUM}"
    
    echo "=== Processing $DEV → $MNT ==="
    mkdir -p "$MNT"
    
    # Detect current mountpoint (if any)
    EXISTING=$(findmnt -n -o TARGET --source "$DEV" | head -n1 || true)
    
    if [ "$EXISTING" == "$MNT" ]; then
        echo "$DEV is already mounted at $MNT, skipping..."
        DISK_NUM=$((DISK_NUM + 1))
        continue
        elif [ -n "$EXISTING" ]; then
        echo "Currently mounted at $EXISTING, unmounting..."
        if ! umount "$EXISTING"; then
            echo "Normal unmount failed, retrying with lazy unmount..."
            umount -l "$EXISTING"
        fi
    fi
    
    # Detect filesystem type
    FSTYPE=$(blkid -o value -s TYPE "$DEV")
    echo "Filesystem type: $FSTYPE"
    
    # Choose mount options
    if [[ "$FSTYPE" == "exfat" || "$FSTYPE" == "ntfs" ]]; then
        OPTS="defaults,uid=0,gid=$GROUP,umask=007"
        mount -t "$FSTYPE" -o $OPTS "$DEV" "$MNT"
    else
        OPTS="defaults"
        mount "$DEV" "$MNT"
        chown -R "$ADMIN:$GROUP" "$MNT"
        chmod -R 770 "$MNT"
        chmod g+s "$MNT"
    fi
    
    # Add/update fstab entry (avoid duplicates)
    if ! grep -q "$MNT" /etc/fstab; then
        echo "$DEV  $MNT  $FSTYPE  $OPTS  0  0" >> /etc/fstab
        echo "Added fstab entry for $DEV → $MNT"
    else
        echo "fstab entry for $MNT already exists"
    fi
    
    echo "Mounted $DEV at $MNT with shared permissions"
    DISK_NUM=$((DISK_NUM + 1))
done

echo "=== All expansions mounted under /mnt/Expansion/* ==="
