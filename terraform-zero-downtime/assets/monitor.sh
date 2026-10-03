#!/usr/bin/env bash
# Live view (optional, for a second terminal tab): one line per second.
LOG="${LOG:-/root/lab/traffic.log}"
printf '%-10s %6s %6s  %s\n' TIME OK FAILED VERSIONS
last=$(wc -l < "$LOG")
while true; do
  sleep 1
  now=$(wc -l < "$LOG")
  tail -n +"$((last + 1))" "$LOG" | head -n "$((now - last))" | awk -v t="$(date +%T)" '
    { if ($2 == "200") ok++; else fail++
      if ($3 != "-" && !($3 in s)) { s[$3] = 1; v = v (v ? "," : "") "v" $3 } }
    END { printf "%-10s %6d %6d  %s\n", t, ok, fail, v }'
  last=$now
done
