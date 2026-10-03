#!/bin/bash
cd /root/lab || exit 1
docker ps --format '{{.Names}}' | grep -q '^lb$' || { echo "Load balancer not running. Did terraform apply succeed?"; exit 1; }
curl -sf -m 3 localhost:8080/ | grep -q 'version=1.0' || { echo "App v1.0 is not answering through the load balancer yet."; exit 1; }
[ -f /root/lab/.score_offset ] || { echo "Run: score start"; exit 1; }
