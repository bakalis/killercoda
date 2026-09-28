#!/bin/bash
set -euo pipefail

cd /root/terraform-iac

terraform state list | grep -q '^docker_network.app$'
terraform state list | grep -q '^docker_container.database$'
terraform state list | grep -q '^docker_container.backend\[0\]$'
terraform state list | grep -q '^docker_container.nginx$'

echo "✓ Terraform state contains the expected managed resources."
