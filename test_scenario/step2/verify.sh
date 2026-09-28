#!/bin/bash
set -euo pipefail

cd /root/terraform-iac

test -f terraform.tfstate
docker inspect terraform-iac-network >/dev/null
docker inspect terraform-backend-0 >/dev/null
docker inspect terraform-postgres >/dev/null
docker inspect terraform-nginx >/dev/null

response="$(curl -fsS http://localhost:8080)"
echo "$response" | grep -q "backend-0"

echo "✓ Terraform-managed application is running."
