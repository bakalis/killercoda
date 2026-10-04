# Done

You measured an outage caused by Terraform's default behaviour and removed it with four lifecycle features, checking each change against real traffic instead of assuming it worked.

**Key takeaways**

- Terraform reporting success does not mean users were unaffected: **measure**.
- Order (`create_before_destroy`) and readiness (`healthcheck` + `wait`) are two separate problems; you need both.
- Hidden dependencies need to be made explicit (`replace_triggered_by`).
- Stateless and stateful resources need opposite treatment (`prevent_destroy`, no overlap).
- Lifecycle rules give *near*-zero downtime for simple topologies. They are not a replacement for a real rollout mechanism.
- Infrastructure as code is also a **record**. Every deployment in this tutorial started as a change to a file: a new version, a new rule, a new banner. Keep those files in Git and apply only what is committed, and each deployment is documented twice: the code says what is running, and the history says who changed it, when and why. Heavily audited environments can use exactly this as their deployment process, because the audit trail is a by-product of the work instead of an extra task.

**Further reading**

- Terraform `lifecycle` meta-argument: https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle
- Docker provider: https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs
