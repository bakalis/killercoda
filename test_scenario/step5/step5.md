# 5. Create and repair configuration drift

Now we will simulate a common operational problem.

A developer has changed the infrastructure **outside Terraform**.

The Terraform configuration still declares:

```text
backend-0 should exist
```

But someone removes it manually.

Run:

```bash
docker rm -f terraform-backend-0
```{{exec}}

Check:

```bash
docker ps --format '{{.Names}}'
```{{exec}}

The backend is gone.

The application should now fail because Nginx has no backend instance to serve.

Try:

```bash
curl http://localhost:8080
```{{exec}}

Now ask Terraform what it thinks should happen:

```bash
cd /root/terraform-iac
terraform plan
```{{exec}}

Terraform should propose recreating the missing backend.

## Repair the drift

Apply the plan:

```bash
terraform apply
```{{exec}}

Then check:

```bash
docker ps --format '{{.Names}}'
```{{exec}}

and:

```bash
curl http://localhost:8080
```{{exec}}

The backend should be running again.

## What happened?

The configuration still described the desired infrastructure.

The actual Docker environment had diverged from it.

That divergence is **configuration drift**.

Terraform allowed us to move the environment back toward the declared state:

```text
       Desired state
       backend-0 exists
              |
              v
        Terraform plan
              |
              v
       backend-0 missing
              |
              v
       Terraform apply
              |
              v
       backend-0 restored
```

This is one of the central ideas behind declarative infrastructure management: describe the desired state and let the tool calculate the changes needed to reach it.

> **CHECK:** The final check should pass only after the backend has been repaired.
