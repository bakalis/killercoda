#!/bin/bash
cd /root/lab || exit 1
grep -q 'create_before_destroy' main.tf || { echo "main.tf has no create_before_destroy"; exit 1; }
grep -q 'terraform_data" "release"' main.tf || { echo "Add the release marker so each container gets a unique name."; exit 1; }
curl -sf -m 3 localhost:8080/ | grep -q 'version=3.0' || { echo "App v3.0 is not serving yet."; exit 1; }
grep -q 'step 3' scoreboard.txt 2>/dev/null || { echo "Record the result: score \"step 3: create_before_destroy\""; exit 1; }
