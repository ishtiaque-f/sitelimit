#!/bin/bash
set -euo pipefail

die() {
  echo "uninstall.sh: $*" >&2
  exit 1
}

[ "$(id -u)" -eq 0 ] || die "must be run as root (sudo ./uninstall.sh)"

systemctl disable --now sitelimit 2>/dev/null || true

rm -f /usr/local/bin/sitelimit-daemon /usr/local/bin/sitelimit
rm -f /etc/systemd/system/sitelimit.service

systemctl daemon-reload

sed -i '/#sitelimit/d' /etc/hosts
resolvectl flush-caches 2>/dev/null || nscd -i hosts 2>/dev/null || true

if [ -d /var/lib/sitelimit ]; then
  printf 'uninstall.sh: delete /var/lib/sitelimit (daily counters)? [y/N] '
  read -r reply || reply=""
  case "$reply" in
    y|Y|yes|YES) rm -rf /var/lib/sitelimit ;;
    *) echo "uninstall.sh: keeping /var/lib/sitelimit" ;;
  esac
fi

echo "uninstall.sh: sitelimit removed (kept /etc/sitelimit.conf - delete it manually if unwanted)"
