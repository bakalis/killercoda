#!/bin/bash
cd /root/lab || exit 1
grep -q 'prevent_destroy *= *true' main.tf || { echo "main.tf has no prevent_destroy = true on the volume"; exit 1; }
docker volume ls --format '{{.Name}}' | grep -q '^store-data$' || { echo "Volume store-data does not exist."; exit 1; }
docker ps --format '{{.Names}}' | grep -q '^store$' || { echo "The store container is not running."; exit 1; }
curl -sf -m 3 localhost:8080/store/important >/dev/null || { echo "The app cannot read the key 'important' from the store. Store it again with the curl -X PUT command."; exit 1; }
terraform plan -destroy -target=docker_volume.data -input=false 2>&1 | grep -q 'prevent_destroy' || { echo "Terraform does not refuse to destroy the volume."; exit 1; }
