#!/bin/bash
cd /root/lab || exit 1
grep -q 'replace_triggered_by' main.tf || { echo "main.tf has no replace_triggered_by"; exit 1; }
curl -sf -m 3 localhost:8080/ | grep -qF "banner=$(cat config/banner.txt)" || { echo "The app is not serving the current content of config/banner.txt yet."; exit 1; }
grep -q 'step 5' scoreboard.txt 2>/dev/null || { echo "Record the result: score \"step 5: config change\""; exit 1; }
