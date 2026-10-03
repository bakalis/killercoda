#!/bin/bash
cd /root/lab || exit 1
grep -q 'healthcheck' main.tf && grep -q 'wait *= *true' main.tf || { echo "main.tf needs a healthcheck block and wait = true"; exit 1; }
curl -sf -m 3 localhost:8080/ | grep -q 'version=4.0' || { echo "App v4.0 is not serving yet."; exit 1; }
docker ps --filter health=healthy --format '{{.Names}}' | grep -q '^app-' || { echo "App container is not reporting healthy."; exit 1; }
grep -q 'step 4' scoreboard.txt 2>/dev/null || { echo "Record the result: score \"step 4: + health check\""; exit 1; }
