# 3. Understand dependencies and state

Terraform is doing more than executing a list of commands.

## Dependencies

Inspect the Terraform graph:

```bash
terraform graph
```{{exec}}

The raw output is Graphviz DOT. You should be able to identify relationships such as:

```text
docker_network.app
       |
       +----------------------+
       |                      |
       v                      v
   PostgreSQL              backend
                              |
                              v
                            Nginx
```

For example, the backend contains:

```hcl
networks_advanced {
  name = docker_network.app.name
}
```

Terraform can therefore infer that the network must exist before the backend container can be created.

The Nginx resource also has:

```hcl
depends_on = [
  docker_container.backend
]
```

because its configuration refers to the backend instances.

## Terraform state

Now inspect the resources Terraform knows about:

```bash
terraform state list
```{{exec}}

You should see resources such as:

```text
docker_network.app
docker_container.database
docker_container.backend[0]
docker_container.nginx
```

Terraform state is part of Terraform's model of the infrastructure it manages. It allows Terraform to relate configuration to concrete resources and determine what needs to change.

Inspect it with:

```bash
terraform show
```{{exec}}

### Key idea

There are three things to keep conceptually separate:

```text
Configuration
    |
    | describes
    v
Desired state

Terraform state
    |
    | records Terraform's knowledge
    v
Managed resources

Docker
    |
    | is the actual environment
    v
Actual state
```

This distinction becomes important when we deliberately create **configuration drift** later.

Use **CHECK** when you have inspected both the dependency graph and Terraform state.
