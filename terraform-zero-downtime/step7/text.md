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

Try to answer each question yourself first. Then open the panel below it and compare.

**1. Why is `create_before_destroy` right for `app` but dangerous for `store`?**

<details><summary>One possible answer</summary>

The app keeps no state. Two copies can run side by side, and it does not matter which one answers a request, so the overlap removes the gap at the price of a little extra capacity for a few seconds.

The store owns data, and that data lives in exactly one volume. In an overlap, two Redis processes would write to the same files and could corrupt them. A new container with its own, empty volume is no better: everything written to the old one would be missing. (In this lab the fixed name `store` would also collide, as `app` did in step 3.)

Replacing a stateful resource without downtime needs a handover that understands the data, for example replication followed by a failover. Terraform can only decide the order of a create and a destroy. That is why the store keeps the default order, accepts a short planned interruption, and gets `prevent_destroy` on its volume.

</details>

**2. Your result may not be exactly zero. Which part of the system would have to change to guarantee it (think: connections in flight, graceful shutdown)?**

<details><summary>One possible answer</summary>

No single part can guarantee it. Three parts have to cooperate, in this order:

1. **The load balancer** stops sending new requests to the old container while that container is still running. Here nginx only finds out afterwards: it looks up the name `app` at most once per second, and otherwise notices when a connection fails.
2. **Whoever stops the container** asks first and waits: `SIGTERM`, a grace period, and `SIGKILL` only after that. The Docker provider uses a grace period of zero unless `destroy_grace_seconds` is set, so in this lab the old container is killed at once.
3. **The application** reacts to `SIGTERM` by finishing the requests it has already accepted, and exits afterwards. Ours exits immediately.

Graceful shutdown in the application is necessary, but on its own it is not enough. Without (2) it never gets the time to run, and without (1) new requests keep arriving at a container that has stopped listening.

Terraform contributes the order "create, wait until healthy, destroy". It has no step for draining in between. In this lab nginx covers the gap: when a connection to the old container fails, it retries the request on the new one (`proxy_next_upstream` in `nginx.conf`). That is why you normally measure 0. It is only safe because the request is a `GET` that can be repeated and none of the answer has been sent yet; a request that changes data must not be retried blindly. Orchestrators have the whole sequence built in. Kubernetes, for example, takes a Pod out of its Service, sends `SIGTERM`, and waits for the grace period before it kills the container.

</details>

**3. Who pays the cost of the overlap in a real cloud (extra instances, quotas, licences)?**

<details><summary>One possible answer</summary>

For the length of the overlap you run both generations, so someone has to pay for, and have room for, twice the resources.

- **Money:** the owner of the cloud bill pays for the extra instances. For one small service and a few minutes that is negligible. For large or GPU instances, or a whole fleet replaced at once, it is not.
- **Capacity:** the headroom must exist before the apply starts: quotas for instances and CPUs, free IP addresses, available machines of that type in the zone. Usually a platform team keeps it free. If it is missing, the create fails. That is the safe kind of failure, because the old instance keeps serving (as in step 3), but the rollout is stuck.
- **Licences:** software licensed per instance or per core may not allow the second copy, not even for a minute.

When the overlap is too expensive, replace a few instances at a time, or accept the default order in a planned maintenance window.

</details>

**4. Kubernetes rolling updates, autoscaling-group instance refresh and blue/green deployments do this job natively. When would you still prefer Terraform lifecycle rules, and when not?**

<details><summary>One possible answer</summary>

**Prefer lifecycle rules** when Terraform already owns the resource and nothing sits between you and it: one VM or container behind a load balancer, a small fleet, an internal tool. Adding an orchestrator only for its rollouts would cost more than it saves. The rules also stay useful next to a platform, for the infrastructure around it: a certificate, a DNS record or a launch template must not disappear while it is being replaced either.

**Prefer a rollout mechanism** when you deploy often, run many replicas or services, or need what Terraform does not offer: shifting traffic gradually (canary), draining connections, and rolling back automatically when the new version turns out to be bad. A failed `terraform apply` simply stops where it is. In that setup Terraform manages the platform, and the platform manages the releases.

</details>

## When this approach is useful, and when it is not

- **Useful:** Terraform already owns the resource, the topology is simple (a pool of identical stateless instances behind one entry point), and a short overlap is acceptable.
- **Not enough:** you need gradual traffic shifting, automatic rollback on errors, connection draining, or you manage many services. A deployment platform (Kubernetes, ECS, ASG refresh) or blue/green with weighted routing is the better tool.
- **For whom:** small teams whose deployment mechanism *is* `terraform apply`. Teams already on a platform with built-in rollouts should use that, and keep Terraform for the platform itself.

## Clean up

`prevent_destroy` will also block the clean-up, which is the point. Lower the guard deliberately:

```bash
sed -i 's/prevent_destroy = true/prevent_destroy = false/' main.tf
```{{exec}}

Then destroy everything:

```bash
terraform destroy -auto-approve
```{{exec}}

If `monitor` is still running in your second tab, stop it with `Ctrl+C`.
