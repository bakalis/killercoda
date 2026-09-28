# Terraform Infrastructure as Code — Killercoda Scenario

A single executable Killercoda scenario demonstrating:

- Infrastructure as Code
- Terraform declarative configuration
- Docker infrastructure
- Terraform state and dependencies
- Configuration drift and reconciliation
- Declarative horizontal scaling
- Nginx load balancing

## Scenario flow

1. Manual infrastructure
2. Terraform provisioning
3. Dependencies and state
4. Infrastructure change through code
5. Deliberate configuration drift
6. Terraform repair
7. Scale backend from 1 to 3
8. Configure Nginx load balancing
9. Reflection

## Killercoda structure

The scenario directory is the repository root. It contains `index.json`, `intro.md`, step directories, and `finish.md`.

Connect the repository to Killercoda's Creator interface and select the branch containing these files.

## Local validation

The scenario is designed for the Ubuntu Killercoda environment and expects Docker access.

The background script installs Terraform 1.16.4 and prepares the Terraform project.
