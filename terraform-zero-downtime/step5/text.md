# Step 5: Roll out config changes with `replace_triggered_by`

**Goal:** handle a change Terraform cannot see by itself.

The app reads `config/banner.txt` once at startup. Terraform only knows the *path* of that file, not its content. Change the content:

```bash
echo "banner v2" > config/banner.txt
terraform plan
curl -s localhost:8080
```{{exec}}

Terraform says **No changes**, and the app still serves the old banner. The change is real but invisible to Terraform.

**Fix:** track the content of the file, and tell the release marker to be replaced whenever that tracker changes. Because the container name comes from the release marker, a new release means a new container:

```diff
+resource "terraform_data" "config" {
+  input = filemd5("${path.module}/config/banner.txt")
+}
+
 resource "terraform_data" "release" {
   triggers_replace = [var.app_version]
+
+  lifecycle {
+    replace_triggered_by = [terraform_data.config]
+  }
 }
```

![Chain of four resources: the content of config/banner.txt is hashed by filemd5 into terraform_data.config. When the hash changes, that resource is updated in place, which replaces terraform_data.release through replace_triggered_by. The new id of the release marker is part of the container name, so the container is replaced. A new app_version replaces the release marker in the same way.](./trigger-chain.svg)

*One changed file sets off the whole chain. A new version enters the same chain one link further down, so both kinds of change end in the same safe rollout.*

Put the change in place:

```bash
diff -u main.tf stages/stage5.tf
cp stages/stage5.tf main.tf
```{{exec}}

Apply it:

```bash
terraform apply -auto-approve
```{{exec}}

Then ask the app for its banner:

```bash
curl -s localhost:8080
```{{exec}}

Only the tracker is created, and the app **still** shows the old banner. That is expected: `replace_triggered_by` reacts to a *change* of the tracker, and creating it for the first time is not a change. From now on it is watching. Change the file again:

```bash
echo "banner v3" > config/banner.txt
terraform plan
```{{exec}}

Read the plan: `terraform_data.config` is updated in place, `terraform_data.release` is **replaced due to changes in replace_triggered_by**, and the container is replaced as a consequence. Apply it:

```bash
terraform apply -auto-approve
```{{exec}}

Record the result and look at the banner again:

```bash
score "step 5: config change"
curl -s localhost:8080
```{{exec}}

The new banner is live, and because the container still has `create_before_destroy` and a health check, the rollout is as clean as the version upgrade in step 4.

**Why this matters:** hidden dependencies (files, templates, secrets referenced by path) are a common reason that infrastructure silently drifts from what the code says. `replace_triggered_by` makes the dependency explicit and reviewable.
