#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LOCUS_CALLER_PWD="${PWD:-$ROOT}"
cd "$ROOT"

LOCUS_UID="$(id -u)"
LOCUS_GID="$(id -g)"
LOCUS_ID="$(printf '%s' "$ROOT" | sha256sum | cut -c1-12)"
LOCUS_PROJECT="locus-${LOCUS_ID}"
LOCUS_IMAGE="locus-${LOCUS_ID}:uid-${LOCUS_UID}"
LOCUS_DATA_VOLUME="locus-data-${LOCUS_ID}"
LOCUS_MOUNTS_FILE="$ROOT/.locus/mounts"
export LOCUS_UID LOCUS_GID LOCUS_ID LOCUS_PROJECT LOCUS_IMAGE LOCUS_DATA_VOLUME
export LOCUS_CALLER_PWD LOCUS_MOUNTS_FILE

LOCUS_PROTECTED_PATHS=(/bin /boot /dev /etc /home/locus /lib /lib32 /lib64 /proc /root /run /sbin /sys /tmp /usr /var /workspace)

locus_protected_path() {
  local target="$1" protected
  [ "$target" = "/" ] && return 0
  for protected in "${LOCUS_PROTECTED_PATHS[@]}"; do
    case "$target" in "$protected"|"$protected"/*) return 0 ;; esac
    case "$protected" in "$target"/*) return 0 ;; esac
  done
  return 1
}

BUILD_HASH="$(
  {
    sha256sum Dockerfile entrypoint.sh tmux.conf bashrc opencode.json
    printf '%s\n' "${LOCUS_UID}:${LOCUS_GID}"
  } | sha256sum | cut -d' ' -f1
)"
export BUILD_HASH

if [ -z "${TZ:-}" ] && [ -r /etc/timezone ]; then
  IFS= read -r TZ < /etc/timezone || true
fi
if [ -z "${TZ:-}" ] && [ -L /etc/localtime ]; then
  localtime="$(readlink -f /etc/localtime 2>/dev/null || true)"
  case "$localtime" in
    */zoneinfo/*) TZ="${localtime#*/zoneinfo/}" ;;
  esac
fi
export TZ="${TZ:-UTC}"

if ! command -v docker >/dev/null 2>&1; then
  echo "locus: docker not found" >&2
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  LOCUS_COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  LOCUS_COMPOSE=(docker-compose)
else
  echo "locus: docker compose not found" >&2
  exit 1
fi
