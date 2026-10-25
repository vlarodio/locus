#!/usr/bin/env bash
set -euo pipefail

export HOME="${HOME:-/home/locus}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export BUN_TMPDIR="${BUN_TMPDIR:-$XDG_CACHE_HOME/opencode/tmp}"
export LOCUS_DATA_VOLUME="${LOCUS_DATA_VOLUME:-locus-data}"

for dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$BUN_TMPDIR"; do
  if ! mkdir -p "$dir" 2>/dev/null; then
    echo "locus: нет прав на запись в $dir (UID $(id -u))." >&2
    echo "locus: удали том командой: docker volume rm $LOCUS_DATA_VOLUME" >&2
    exit 1
  fi
done

if ! touch "$HOME/.locus-write-test" 2>/dev/null; then
  echo "locus: нет прав на запись в $HOME (UID $(id -u))." >&2
  echo "locus: удали том командой: docker volume rm $LOCUS_DATA_VOLUME" >&2
  exit 1
fi
rm -f "$HOME/.locus-write-test"

cd /workspace

if [ "$#" -eq 0 ]; then
  if [ -t 0 ] && [ -t 1 ]; then
    exec tmux -f /etc/locus/tmux.conf new-session -s locus
  fi
  exec bash --noprofile --norc
fi

if [ "${1#-}" != "$1" ]; then
  exec opencode "$@"
fi

exec "$@"
