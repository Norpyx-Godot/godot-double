#!/usr/bin/env bash
set -euo pipefail

uid="${LOCAL_UID:-1000}"
gid="${LOCAL_GID:-1000}"

if [[ "$uid" == "0" ]]; then
  printf 'error: LOCAL_UID=0 would run makepkg as root; use a non-root uid\n' >&2
  exit 1
fi

if ! getent group "$gid" >/dev/null 2>&1; then
  groupadd -g "$gid" gdops
fi

if ! getent passwd "$uid" >/dev/null 2>&1; then
  useradd -m -u "$uid" -g "$gid" -G wheel gdops
fi

user_name="$(getent passwd "$uid" | cut -d: -f1)"
user_home="$(getent passwd "$uid" | cut -d: -f6)"

install -d -o "$uid" -g "$gid" "$user_home"
printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$user_name" > "/etc/sudoers.d/$user_name"
chmod 0440 "/etc/sudoers.d/$user_name"

cd /workspace
exec sudo -E -H -u "$user_name" "$@"
