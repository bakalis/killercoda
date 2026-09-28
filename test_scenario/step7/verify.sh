#!/bin/bash
set -euo pipefail

docker exec terraform-nginx nginx -T 2>/dev/null | grep -q 'terraform-backend-0:8080'
docker exec terraform-nginx nginx -T 2>/dev/null | grep -q 'terraform-backend-1:8080'
docker exec terraform-nginx nginx -T 2>/dev/null | grep -q 'terraform-backend-2:8080'

for i in 0 1 2; do
  docker inspect "terraform-backend-$i" >/dev/null
done

response="$(curl -fsS http://localhost:8080)"
echo "$response" | grep -q 'backend-'

echo "✓ Nginx is configured with all three backend replicas."
