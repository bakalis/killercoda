# Step 7: Reflect and clean up

Print your scoreboard:

```bash
score show
```{{exec}}

You should see the failure count and outage length drop from step 2 to step 4, and step 5 confirm that the same safe rollout also works for config changes.

## What each rule solved

| Rule | Problem it solved | New constraint it introduced |
|---|---|---|
| `create_before_destroy` | Gap between destroy and create | Names, ports and other identifiers must be unique per generation; temporarily double capacity |
| `healthcheck` + `wait = true` | "Created" is not "ready" | You must define a meaningful readiness check; applies take longer |
| `replace_triggered_by` | Config changes Terraform cannot see | You must name the dependency explicitly |
| `prevent_destroy` | Accidental loss of stateful data | Deliberate removal needs an extra code change |

## Questions to think about

1. Why is `create_before_destroy` right for `app` but dangerous for `store`?
2. Your result may not be exactly zero. Which part of the system would have to change to guarantee it (think: connections in flight, graceful shutdown)?
3. Who pays the cost of the overlap in a real cloud (extra instances, quotas, licences)?
4. Kubernetes rolling updates, autoscaling-group instance refresh and blue/green deployments do this job natively. When would you still prefer Terraform lifecycle rules, and when not?

## When this approach is useful, and when it is not

- **Useful:** Terraform already owns the resource, the topology is simple (a pool of identical stateless instances behind one entry point), and a short overlap is acceptable.
- **Not enough:** you need gradual traffic shifting, automatic rollback on errors, connection draining, or you manage many services. A deployment platform (Kubernetes, ECS, ASG refresh) or blue/green with weighted routing is the better tool.
- **For whom:** small teams whose deployment mechanism *is* `terraform apply`. Teams already on a platform with built-in rollouts should use that, and keep Terraform for the platform itself.

## Clean up

`prevent_destroy` will also block the clean-up, which is the point. Lower the guard deliberately, then destroy everything:

```bash
sed -i 's/prevent_destroy = true/prevent_destroy = false/' main.tf
terraform destroy -auto-approve
```{{exec}}
