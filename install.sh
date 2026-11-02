#!/bin/bash
set -euo pipefail

DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

die() {
  echo "install.sh: $*" >&2
  exit 1
}

[ "$(id -u)" -eq 0 ] || die "must be run as root (sudo ./install.sh)"

for cmd in xdotool wmctrl; do
  command -v "$cmd" >/dev/null 2>&1 \
    || die "$cmd not found - install it first (sudo apt install xdotool wmctrl)"
done

command -v systemctl >/dev/null 2>&1 || die "systemctl not found - systemd is required"

for f in sitelimit-daemon sitelimit sitelimit.conf sitelimit.service; do
  [ -f "$DIR/$f" ] || die "missing $DIR/$f"
done

install -m 0755 "$DIR/sitelimit-daemon" /usr/local/bin/sitelimit-daemon
install -m 0755 "$DIR/sitelimit" /usr/local/bin/sitelimit

if [ -e /etc/sitelimit.conf ]; then
  echo "install.sh: keeping existing /etc/sitelimit.conf"
else
  install -m 0644 "$DIR/sitelimit.conf" /etc/sitelimit.conf
fi

install -m 0644 "$DIR/sitelimit.service" /etc/systemd/system/sitelimit.service

mkdir -p /var/lib/sitelimit

systemctl daemon-reload
systemctl enable --now sitelimit

echo "install.sh: sitelimit installed and started"
