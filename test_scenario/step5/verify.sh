#!/bin/bash
set -euo pipefail

docker inspect terraform-backend-0 >/dev/null

response="$(curl -fsS http://localhost:8080)"
echo "$response" | grep -q "Terraform-managed"

echo "✓ Configuration drift was repaired through Terraform."
