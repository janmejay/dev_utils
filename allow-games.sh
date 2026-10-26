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

ALLOWANCE_FILE="${GAME_ALLOWANCE_FILE:-/var/run/game-allowance}"

if [[ $# -ne 1 ]] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 <minutes>" >&2
  exit 1
fi

minutes=$1
until=$(( $(date +%s) + minutes * 60 ))
echo "$until" > "$ALLOWANCE_FILE"

# `date -r` is macOS/BSD; `date -d @` is GNU/Linux.
human=$(date -r "$until" 2>/dev/null || date -d "@$until" 2>/dev/null || echo "epoch $until")
echo "Games allowed for $minutes minute(s), until $human."
