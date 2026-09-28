#!/bin/bash
set -euo pipefail

LAB_DIR="/root/terraform-iac"

apt-get update -qq
apt-get install -y -qq curl unzip jq

TERRAFORM_VERSION="1.16.4"
ARCH="amd64"

if ! command -v terraform >/dev/null 2>&1 || [ "$(terraform version -json | jq -r '.terraform_version')" != "$TERRAFORM_VERSION" ]; then
  curl -fsSLo /tmp/terraform.zip \
    "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip"
  unzip -o /tmp/terraform.zip -d /usr/local/bin >/dev/null
  rm -f /tmp/terraform.zip
fi

mkdir -p "$LAB_DIR"
cd "$LAB_DIR"

cat > .gitignore <<'EOF'
.terraform/
terraform.tfstate
terraform.tfstate.backup
.terraform.lock.hcl
crash.log
EOF

cat > versions.tf <<'EOF'
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

provider "docker" {}
EOF

cat > variables.tf <<'EOF'
variable "backend_replicas" {
  description = "Number of backend containers."
  type        = number
  default     = 1

  validation {
    condition     = var.backend_replicas >= 1 && var.backend_replicas <= 3
    error_message = "backend_replicas must be between 1 and 3."
  }
}
EOF

cat > main.tf <<'EOF'
resource "docker_network" "app" {
  name = "terraform-iac-network"
}

resource "docker_image" "backend" {
  name = "hashicorp/http-echo:1.0"
}

resource "docker_image" "postgres" {
  name = "postgres:16-alpine"
}

resource "docker_image" "nginx" {
  name = "nginx:1.27-alpine"
}

resource "docker_container" "database" {
  name  = "terraform-postgres"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_PASSWORD=devops",
    "POSTGRES_DB=demo"
  ]

  networks_advanced {
    name = docker_network.app.name
  }
}

resource "docker_container" "backend" {
  count = var.backend_replicas

  name  = "terraform-backend-${count.index}"
  image = docker_image.backend.image_id

  command = [
    "-listen=:8080",
    "-text=Hello from backend-${count.index}"
  ]

  networks_advanced {
    name = docker_network.app.name
  }
}

locals {
  backend_upstreams = join("\n", [
    for i in range(var.backend_replicas) :
    "        server terraform-backend-${i}:8080;"
  ])

  nginx_config = <<-NGINX
    upstream backend {
    ${local.backend_upstreams}
    }

    server {
        listen 80;

        location / {
            proxy_pass http://backend;
        }
    }
  NGINX
}

resource "docker_container" "nginx" {
  name  = "terraform-nginx"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = docker_network.app.name
  }

  upload {
    file        = "/etc/nginx/conf.d/default.conf"
    content     = local.nginx_config
    permissions = "0644"
  }

  depends_on = [
    docker_container.backend
  ]
}

output "application_url" {
  value = "http://localhost:8080"
}

output "backend_containers" {
  value = [for container in docker_container.backend : container.name]
}
EOF

terraform -chdir="$LAB_DIR" init -input=false >/dev/null
echo "Terraform $(terraform version -json | jq -r '.terraform_version') installed."
echo "Lab prepared in $LAB_DIR"
