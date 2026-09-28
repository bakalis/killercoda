# 6. Scale the service to three replicas

The application is receiving more traffic.

The new requirement is:

> Run three backend instances instead of one.

We will implement this as an **infrastructure change through Terraform**.

Open:

```bash
nano /root/terraform-iac/variables.tf
```

Change:

```hcl
default = 1
```

to:

```hcl
default = 3
```

The resource already uses:

```hcl
count = var.backend_replicas
```

so the desired infrastructure has changed from:

```text
backend-0
```

to:

```text
backend-0
backend-1
backend-2
```

## Preview the change

Run:

```bash
cd /root/terraform-iac
terraform plan
```

Look for Terraform proposing two additional backend containers.

Notice that you did **not** tell Terraform:

```text
create backend-1
create backend-2
```

You changed the desired state:

```text
backend_replicas = 3
```

Terraform calculated the concrete operations.

## Apply the scaling change

Run:

```bash
terraform apply
```

Then:

```bash
docker ps --format '{{.Names}}'
```

You should now see:

```text
terraform-backend-0
terraform-backend-1
terraform-backend-2
```

At this point there are three backend instances, but Nginx still needs to know about them.

That is the next infrastructure change.

> **CHECK:** Confirm that all three backend containers exist.
