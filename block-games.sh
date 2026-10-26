#!/usr/bin/env bash
# =============================================================================
# Game time-allowance gate (macOS/Linux, run as root)
# -----------------------------------------------------------------------------
# Two scripts work together:
#   allow-games.sh <minutes>  -> grants a time-limited allowance
#   block-games.sh            -> cron job; kills games unless an allowance is active
#
# They share an allowance file (default: /var/run/game-allowance) that holds a
# single unix epoch timestamp: the instant the allowance expires. While
# `now < that timestamp`, block-games.sh leaves games alone; otherwise it kills
# them. /var/run is cleared on reboot, so a reboot fails safe to "blocked".
#
# SETUP (as root):
#   sudo cp allow-games.sh block-games.sh /usr/local/bin/
#   sudo chmod 755 /usr/local/bin/allow-games.sh /usr/local/bin/block-games.sh
#
# HOOK UP THE CRON JOB (runs block-games.sh every minute as root):
#   sudo crontab -e
#   # then add this line:
#   * * * * * /usr/local/bin/block-games.sh
#
# GRANT PLAY TIME (e.g. 90 minutes from now):
#   sudo /usr/local/bin/allow-games.sh 90
#
# REVOKE IMMEDIATELY:
#   sudo rm -f /var/run/game-allowance
#
# Override the allowance file path via the GAME_ALLOWANCE_FILE env var.
# =============================================================================
set -euo pipefail

GAME_PATH='Library/Application Support/Steam/steamapps/common'
ALLOWANCE_FILE="${GAME_ALLOWANCE_FILE:-/var/run/game-allowance}"

allowance_active() {
  [[ -f "$ALLOWANCE_FILE" ]] || return 1
  local until
  until=$(tr -dc '0-9' < "$ALLOWANCE_FILE") || return 1
  [[ -n "$until" ]] || return 1
  (( $(date +%s) < until ))
}

# Seed PIDs, matched two ways so wrappers AND the real game binary are caught:
#   - pgrep -f : matches the full argv, catching launcher/wrapper scripts that
#                carry the Steam path in their arguments (e.g. the /bin/bash
#                shim whose own executable is /bin/bash, not under Steam).
#   - ps comm  : matches the executable's real path, catching game binaries
#                invoked via a relative argv[0] like "./Stardew Valley" (whose
#                argv has no path, but whose comm resolves under the Steam dir).
collect_seeds() {
  pgrep -f -- "$GAME_PATH" 2>/dev/null || true
  ps -axo pid=,comm= | awk -v p="$GAME_PATH" 'index($0, p) { print $1 }'
}

# Print the given PIDs plus every descendant. Snapshot the pid/ppid table once,
# then walk it breadth-first. Written for bash 3.2 (macOS /bin/bash): no
# associative arrays, no mapfile.
collect_tree() {
  local table all frontier next kids k pp c
  table=$(ps -axo pid=,ppid=)
  all="$*"
  frontier="$*"
  while [ -n "$frontier" ]; do
    kids=""
    for pp in $frontier; do
      c=$(printf '%s\n' "$table" | awk -v pp="$pp" '$2==pp { print $1 }')
      kids="$kids $c"
    done
    next=""
    for k in $kids; do
      case " $all " in
        *" $k "*) ;;
        *) next="$next $k"; all="$all $k" ;;
      esac
    done
    frontier="$next"
  done
  echo "$all"
}

# Re-scan and signal the full tree. Returns non-zero when nothing matches so the
# caller can bail (TERM pass) or quietly finish (KILL pass).
kill_pass() {
  local sig="$1" seeds pids p
  seeds=$(collect_seeds | sort -u)
  [ -z "$seeds" ] && return 1
  pids=$(collect_tree $seeds)
  for p in $pids; do
    kill "-$sig" "$p" 2>/dev/null || true
  done
  return 0
}

if allowance_active; then
  exit 0
fi

# SIGTERM first for a clean shutdown (lets games save state)...
kill_pass TERM || exit 0
sleep 2
# ...then SIGKILL anything that ignored it (re-scanned in case the tree shifted).
kill_pass KILL || true
