#!/bin/bash
set -euo pipefail

response="$(curl -fsS http://localhost:8080)"
echo "$response" | grep -q "Terraform-managed"

echo "✓ Infrastructure was changed through Terraform."
