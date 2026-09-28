#!/bin/bash
set -euo pipefail

for i in 0 1 2; do
  docker inspect "terraform-backend-$i" >/dev/null
done

count="$(docker ps --filter 'name=terraform-backend-' --format '{{.Names}}' | wc -l)"
test "$count" -eq 3

echo "✓ Three backend replicas are running."
