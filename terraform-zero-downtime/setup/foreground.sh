#!/bin/bash
clear
echo -n "Preparing the environment (Terraform, Docker images, traffic generator) "
while [ ! -f /tmp/setup-done ]; do echo -n "."; sleep 1; done
echo
echo "Ready. Click START to begin."
cd /root/lab
