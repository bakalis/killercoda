#!/bin/bash
cd /root/lab || exit 1
grep -q '2.0' terraform.tfvars || { echo "terraform.tfvars should set app_version to 2.0"; exit 1; }
curl -sf -m 3 localhost:8080/ | grep -q 'version=2.0' || { echo "App v2.0 is not serving yet."; exit 1; }
grep -q 'step 2' scoreboard.txt 2>/dev/null || { echo "Record the result: score \"step 2: default order\""; exit 1; }
