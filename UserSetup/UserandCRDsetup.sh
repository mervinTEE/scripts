#!/bin/bash
# UserandCRDsetup.sh
# Usage:
#   sudo bash UserandCRDsetup.sh <username> <password>

set -euo pipefail

USER=$1
PASS=$2
ADMIN="admin"
GROUP="sharedgroup"
SHARE_SRC="/mnt/hdd/PC"
SHARE_DEST="/home/$USER/PC"

echo "=== Creating new CRD user: $USER ==="

# 1. Create user if not exists
if id "$USER" &>/dev/null; then
    echo "User $USER already exists"
else
    adduser --gecos "" --disabled-password "$USER"
    echo "$USER:$PASS" | chpasswd
    usermod -aG sudo "$USER"
fi

# 2. Install Chrome Remote Desktop + XFCE
apt-get update
apt-get install -y wget curl xfce4 xfce4-goodies desktop-base xscreensaver \
chrome-remote-desktop

# 3. Set CRD session to XFCE
echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /home/$USER/.chrome-remote-desktop-session
chown $USER:$USER /home/$USER/.chrome-remote-desktop-session

# 4. Setup shared group
if ! getent group "$GROUP" >/dev/null; then
    echo "Creating group $GROUP..."
    groupadd "$GROUP"
fi
usermod -aG "$GROUP" "$ADMIN"
usermod -aG "$GROUP" "$USER"

# 5. Fix ownership of /mnt/hdd/PC
if [ -d "$SHARE_SRC" ]; then
    chown -R "$ADMIN:$GROUP" "$SHARE_SRC"
    chmod -R 770 "$SHARE_SRC"
    chmod g+s "$SHARE_SRC"
else
    echo "Warning: $SHARE_SRC does not exist, skipping"
fi

# 6. Bind mount shared folder into user home
mkdir -p "$SHARE_DEST"
if ! grep -q "$SHARE_DEST" /etc/fstab; then
    echo "$SHARE_SRC   $SHARE_DEST   none   bind   0   0" >> /etc/fstab
    echo "Added bind mount for $USER"
fi
mount -a

echo "=== Setup complete for $USER ==="
echo "Next: Visit https://remotedesktop.google.com/headless to register this machine with your Google account."
