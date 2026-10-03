#!/usr/bin/env bash
# score start        -> set the start marker (nothing is printed)
# score "<label>"    -> wait for traffic to settle, report failures since the last marker,
#                       add a row to the scoreboard, move the marker
# score show         -> print the scoreboard
LOG="${LOG:-/root/lab/traffic.log}"
STATE=/root/lab/.score_offset
BOARD=/root/lab/scoreboard.txt

case "${1:-}" in
  start) wc -l < "$LOG" > "$STATE"; echo "Marker set."; exit 0 ;;
  show)  cat "$BOARD" 2>/dev/null || echo "Scoreboard is empty."; exit 0 ;;
  "")    echo 'usage: score start | score "<label>" | score show'; exit 1 ;;
esac

label="$1"
echo "Letting traffic settle for 10 seconds..."
sleep 10

offset=$(cat "$STATE" 2>/dev/null || echo 0)
total=$(wc -l < "$LOG")
[ -f "$BOARD" ] || printf '%-36s %7s %11s  %s\n' "STEP" "FAILED" "OUTAGE (s)" "VERSIONS SEEN" > "$BOARD"

row=$(tail -n +"$((offset + 1))" "$LOG" | awk -v label="$label" '
  { if ($2 == "200") ok++; else { fail++; if (!first) first = $1; last = $1 }
    if ($3 != "-" && !($3 in seen)) { seen[$3] = 1; vers = vers (vers ? "," : "") "v" $3 } }
  END { out = fail ? last - first + 0.1 : 0
        printf "%-36s %7d %11.1f  %s\n", label, fail, out, vers }')
echo "$row" >> "$BOARD"
echo "$total" > "$STATE"
echo
head -1 "$BOARD"
echo "$row"
