# 1. The problem: manual infrastructure

Before using Terraform, let's see the problem that Infrastructure as Code is intended to solve.

Create a Docker network and a backend container manually:

```bash
docker network create manual-demo-network

docker run -d \
  --name manual-demo-backend \
  --network manual-demo-network \
  hashicorp/http-echo:1.0 \
  -listen=:8080 \
  -text="Hello from the manually deployed backend"
```{{exec}}

Verify the container:

```bash
docker ps
```{{exec}}

And query it:

```bash
curl http://localhost:8080
```{{exec}}

There is nothing wrong with these commands. The problem is that the infrastructure is encoded as a **sequence of imperative commands**.

Imagine that this application now needs:

- a database;
- a reverse proxy;
- three backend instances;
- reproducible deployments;
- a reviewable history of infrastructure changes.

A long sequence of shell commands becomes difficult to reason about and reproduce.

## Infrastructure as Code

With IaC, we describe the **desired infrastructure** as code.

Instead of saying:

> Run these commands in this order.

we can describe:

> A network exists, three backend instances exist, and an Nginx proxy routes traffic to them.

Terraform can then determine which operations are needed to make reality match that desired state.

In the next step, we will replace the manual deployment with Terraform.

> You do not need to remove the manual container yet. The Terraform-managed application will use different names.
