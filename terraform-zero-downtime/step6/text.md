# Step 6: Protect stateful data with `prevent_destroy`

**Goal:** see why the rules that fixed the app must **not** be copied to the data tier, and add a guard.

Add a data store (Redis) with a volume. Note what is *absent*: no `create_before_destroy`. Two instances sharing one volume could corrupt data, so for stateful resources an overlap is the wrong choice.

```bash
diff -u main.tf stages/stage6a.tf
cp stages/stage6a.tf main.tf
terraform apply -auto-approve
docker exec store redis-cli set important "do not lose me"
docker exec store redis-cli get important
```{{exec}}

## What an accident looks like

Without protection, one command removes the volume. (`-target` is normally for debugging only; here it simulates a mistake. Terraform also destroys everything that depends on the volume, so the store container goes with it.)

```bash
terraform destroy -target=docker_volume.data -auto-approve
terraform apply -auto-approve
docker exec store redis-cli get important
```{{exec}}

The key is gone (`(nil)`). Terraform did exactly what it was asked to do.

## Add the guard

```diff
 resource "docker_volume" "data" {
   name = "store-data"
+
+  lifecycle {
+    prevent_destroy = true
+  }
 }
```

```bash
diff -u main.tf stages/stage6b.tf
cp stages/stage6b.tf main.tf
terraform apply -auto-approve
docker exec store redis-cli set important "do not lose me"
terraform destroy -target=docker_volume.data -auto-approve
```{{exec}}

Terraform now refuses with **Instance cannot be destroyed**, at *plan* time, before touching anything. Confirm the data survived:

```bash
docker exec store redis-cli get important
```{{exec}}

**Limits of the guard:** `prevent_destroy` is a seatbelt, not a vault. It is only a flag in your code: whoever deletes the line (or the whole resource block) removes it, and it does not protect against actions outside Terraform. It catches *mistakes*, and it makes deliberate removal an explicit, reviewable code change.
