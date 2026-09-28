# 2. Provision the application with Terraform

The lab has prepared a Terraform configuration in:

```bash
cd /root/terraform-iac
```

Inspect it:

```bash
sed -n '1,240p' main.tf
```

Notice the resources:

- a Docker network;
- a PostgreSQL container;
- a backend container;
- an Nginx container.

The backend currently has:

```hcl
backend_replicas = 1
```

and therefore Terraform will create one backend instance.

## Initialize Terraform

Terraform first needs to install its provider:

```bash
terraform init
```

The Docker provider allows Terraform to manage Docker resources through the Docker API.

## Preview the changes

Run:

```bash
terraform plan
```

Read the plan before applying it.

You should see resources being added.

## Apply the configuration

Now create the infrastructure:

```bash
terraform apply
```

Type `yes` when Terraform asks for confirmation.

Check the resulting containers:

```bash
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
```

Finally, query the application:

```bash
curl http://localhost:8080
```

You should receive a response from `backend-0`.

### Why `plan` matters

`terraform plan` gives the operator an opportunity to inspect the proposed infrastructure change before modifying the environment.

The workflow is:

```text
Terraform configuration
        |
        v
   terraform plan
        |
        v
 proposed changes
        |
        v
   terraform apply
        |
        v
 Docker infrastructure
```

Use **CHECK** after confirming that the application is responding.
