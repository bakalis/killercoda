#!/usr/bin/env bash
# Traffic generator: ~10 requests/second to the load balancer.
# Each line in the log: <epoch.seconds> <http status> <version served>
# Status 000 = no connection at all. Anything other than 200 counts as a failed request.
TARGET="${TARGET:-http://localhost:8080/}"
LOG="${LOG:-/root/lab/traffic.log}"
mkdir -p "$(dirname "$LOG")"
: > "$LOG"
while true; do
  ts=$(date +%s.%N)
  out=$(curl -s -m 3 -w ' %{http_code}' "$TARGET" 2>/dev/null)
  code=${out##* }
  if [[ $out =~ version=([^[:space:]]+) ]]; then ver=${BASH_REMATCH[1]}; else ver=-; fi
  echo "$ts $code $ver" >> "$LOG"
  sleep 0.1
done
