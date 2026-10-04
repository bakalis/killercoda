# Zero-downtime infrastructure changes with Terraform lifecycle rules

**Estimated time:** 25–30 minutes. **Requirements:** none (everything runs in this browser session, no accounts).

## The problem

When Terraform has to *replace* a resource (for example a container whose image changed), its default is to **destroy the old one first and then create the new one**. For a service behind a load balancer, the gap between those two actions is an outage, even though `terraform apply` finishes with "Apply complete!".

In this tutorial you will **measure** that outage with a traffic generator and then remove it, one Terraform lifecycle rule at a time.

## Learning outcomes

By the end you will be able to:

1. Explain Terraform's default replacement order and why it causes downtime.
2. Apply `create_before_destroy`, a health check with `wait`, `replace_triggered_by` and `prevent_destroy`, and explain which problem each one solves.
3. Distinguish stateless resources (safe to replace) from stateful ones (must be protected).
4. Judge when lifecycle rules are enough and when a dedicated rollout mechanism is the better tool.

## Architecture

![Architecture of the lab: the traffic generator calls the nginx load balancer on localhost:8080. The load balancer looks up "app" in Docker DNS and forwards each request to the app container. From step 6 the app reads and writes values in a Redis store, which keeps them on a data volume. Terraform manages everything on the Docker network; the traffic generator runs outside it.](./architecture.svg)

*Requests travel down the left column, and from step 6 on into the store. Terraform changes the stack while the traffic generator, which Terraform does not manage, keeps measuring it.*

| Component | Managed by Terraform? | Why |
|---|---|---|
| `lb` (nginx) | yes | Load balancer, the only published port. It looks up the name `app` through Docker DNS on every request, so it automatically follows containers that appear or disappear. |
| `app-<id>` | yes | The stateless application we keep upgrading. Takes 5 seconds to boot (simulated), so "running" and "ready" are different moments. It keeps no data itself. |
| `store` + volume | yes (step 6) | Stateful tier: the app reads and writes its values here. Needs the opposite treatment from the app. |
| `traffic-gen` | **no** | The observer must not be replaced by the experiment it measures. |

## How you will measure

The traffic generator is already running. Two helper commands read its log:

- `score start` sets a marker.
- `score "label"` waits 10 seconds for traffic to settle, then prints how many requests **failed** (anything other than HTTP 200) and the **outage length** since the marker, and adds a row to a scoreboard.

You will fill the scoreboard step by step and compare it in the last step.

## How the steps work

Each step shows what changes in `main.tf` (as a diff), applies it with a single command, runs `terraform apply`, and records a score. You are welcome to make the edit yourself instead of copying the prepared file; the result must be the same.

The environment is being prepared in the background. Wait for the terminal to print **Ready**, then click **START**.
