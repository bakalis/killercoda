# 7. Add load balancing with Nginx

Three backend containers are now running:

```text
backend-0
backend-1
backend-2
```

But creating capacity is not enough. Traffic must be distributed across those instances.

Terraform already generates the Nginx configuration from `backend_replicas`.

Inspect the relevant part:

```bash
cd /root/terraform-iac
sed -n '55,120p' main.tf
```

The configuration is constructed from:

```hcl
local.backend_upstreams
```

When `backend_replicas = 3`, Terraform generates an Nginx upstream similar to:

```nginx
upstream backend {
    server terraform-backend-0:8080;
    server terraform-backend-1:8080;
    server terraform-backend-2:8080;
}
```

Nginx then proxies requests to:

```nginx
proxy_pass http://backend;
```

## Apply the infrastructure change

Run:

```bash
terraform plan
```

Terraform should detect that the Nginx configuration needs to change.

Apply it:

```bash
terraform apply
```

Now Nginx is the load-balancing layer:

```text
                         Nginx
                      load balancer
                           |
              +------------+------------+
              |            |            |
              v            v            v
         backend-0     backend-1     backend-2
```

## Observe the load balancing

Run several requests:

```bash
for i in {1..12}; do
  curl -s http://localhost:8080
  echo
done
```

You should see responses from different backend containers.

The exact order is not guaranteed, because Nginx controls request distribution.

## Why this is still Infrastructure as Code

The load-balancing layer was not configured by manually editing the running Nginx container.

The desired infrastructure is represented in Terraform:

```text
backend_replicas = 3
        |
        +--> create backend-0
        +--> create backend-1
        +--> create backend-2
        |
        +--> configure Nginx
                  |
                  +--> backend-0
                  +--> backend-1
                  +--> backend-2
```

One change to the desired configuration therefore affects multiple interacting infrastructure components.

> **CHECK:** Verify that the Nginx configuration contains all three backend names and that requests are reaching the application.
