#!/bin/bash
# Prepares the environment while the learner reads the intro.
# It installs tools and files; it never does any of the lab steps for the learner.
exec > /tmp/setup.log 2>&1
set -x

TF_VERSION=1.9.8

# 1. wait for the uploaded assets
for i in $(seq 1 60); do [ -f /root/assets/stage1.tf ] && break; sleep 1; done

# 2. Terraform
if ! command -v terraform >/dev/null; then
  command -v unzip >/dev/null || { apt-get update -qq; apt-get install -y -qq unzip; }
  for i in 1 2 3; do
    curl -fsSL -o /tmp/tf.zip "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" && break
    sleep 3
  done
  unzip -o -q /tmp/tf.zip -d /usr/local/bin terraform
fi

# 3. Docker must be ready; pre-pull images so that applies are fast later
for i in $(seq 1 60); do docker info >/dev/null 2>&1 && break; sleep 1; done
docker pull -q python:3.12-alpine &
docker pull -q nginx:1.27-alpine &
docker pull -q redis:7-alpine &
wait

# 4. Lab directory
mkdir -p /root/lab/app /root/lab/config /root/lab/stages
cd /root/lab
cp /root/assets/Dockerfile /root/assets/app.py app/
cp /root/assets/nginx.conf .
cp /root/assets/banner.txt config/
cp /root/assets/stage*.tf stages/
cp stages/stage1.tf main.tf
echo 'app_version = "1.0"' > terraform.tfvars

# 5. Helper commands
install -m 0755 /root/assets/score.sh   /usr/local/bin/score
install -m 0755 /root/assets/monitor.sh /usr/local/bin/monitor
install -m 0755 /root/assets/traffic.sh /usr/local/bin/traffic-gen

# 6. Provider cache: warm it so the learner's "terraform init" is quick
mkdir -p /root/.terraform.d/plugin-cache
echo 'plugin_cache_dir = "/root/.terraform.d/plugin-cache"' > /root/.terraformrc
mkdir -p /tmp/warm && cp /root/lab/main.tf /tmp/warm/ && (cd /tmp/warm && terraform init -input=false)

# 7. Traffic generator (runs for the whole session, outside Terraform)
setsid nohup traffic-gen >/dev/null 2>&1 &

touch /tmp/setup-done
