#!/bin/bash
# Killercoda types this file into the learner's terminal, so every command shows
# up there. The braces make the shell read the whole block before it runs any of
# it: "clear" then wipes the typed text, and only the two messages remain.
{
  clear
  echo -n "Preparing the environment (Terraform, Docker images, traffic generator) "
  while [ ! -f /tmp/setup-done ]; do echo -n "."; sleep 1; done
  echo
  echo "Ready. Click START to begin."
  echo
  cd /root/lab
  read -r -t 0.2 _ # swallow the Enter that follows this file; it would print an empty prompt
}
