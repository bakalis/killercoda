# 8. Reflection

You have now taken the application through four infrastructure states:

```text
Manual deployment
       |
       v
Terraform-managed application
       |
       v
Configuration drift
       |
       v
Terraform repair
       |
       v
Three replicas + load balancing
```

## What Terraform gave us

### Declarative infrastructure

We described the desired infrastructure rather than scripting every operational step.

### Reviewable changes

`terraform plan` lets an operator inspect proposed changes before applying them.

### Reconciliation

When the actual infrastructure diverged from the declared configuration, Terraform could calculate a repair.

### Reproducibility

The application infrastructure can be recreated from the Terraform configuration.

### Dependency management

Terraform models relationships between resources and uses them to determine a safe ordering for operations.

## Design decisions

### Why Docker?

Docker makes the exercise self-contained and reproducible inside Killercoda. No cloud account, credentials or paid infrastructure are required.

### Why Terraform?

Terraform is useful when infrastructure contains multiple resources whose lifecycle should be described, reviewed and automated as a unit.

### Why not use Terraform for everything?

Terraform is not an application runtime or a replacement for every DevOps tool.

For example:

- Nginx handles runtime HTTP routing.
- Docker provides container execution.
- PostgreSQL provides data storage.
- A CI/CD system can build and release application artifacts.
- Kubernetes can provide runtime orchestration when the deployment requirements become more complex.

Terraform's role here is to **declare and manage the infrastructure** connecting those components.

## Questions to consider

1. What would happen if the number of backend replicas were changed from 3 to 2?
2. What would happen if somebody manually removed `backend-1`?
3. Why is `terraform plan` valuable in a team workflow?
4. What would need to change to deploy this architecture on a cloud provider?
5. At what point would Docker + Terraform become less suitable than a container orchestrator such as Kubernetes?

The key lesson is:

> **Infrastructure as Code is not simply storing shell commands in Git. It is using a declarative description of infrastructure so that changes can be reviewed, reproduced and reconciled automatically.**
