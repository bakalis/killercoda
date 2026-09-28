# 4. Change infrastructure through code

A major benefit of IaC is that infrastructure changes can be represented as code.

Suppose the backend needs a different response message.

Open the Terraform configuration:

```bash
nano /root/terraform-iac/main.tf
```

Find:

```hcl
-text=Hello from backend-${count.index}
```

Change it to:

```hcl
-text=Hello from the Terraform-managed backend-${count.index}
```

Save the file.

Now preview the change:

```bash
cd /root/terraform-iac
terraform plan
```

Terraform should detect that the backend container configuration has changed.

Apply the change:

```bash
terraform apply
```

Then:

```bash
curl http://localhost:8080
```

You should see the new response.

## Why this is different from the manual approach

We did not manually execute a Docker command to update the container.

Instead:

```text
Change desired configuration
          |
          v
   terraform plan
          |
          v
    review change
          |
          v
   terraform apply
          |
          v
 updated infrastructure
```

This makes infrastructure changes visible in code and gives the operator an explicit review point before applying them.

> **CHECK:** Confirm that the response contains `Terraform-managed`.
