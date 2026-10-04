# Step 6: Protect stateful data with `prevent_destroy`

**Goal:** see why the rules that fixed the app must **not** be copied to the data tier, and add a guard.

Add a data store (Redis) with a volume. The app has been waiting for it: its `/store/<key>` routes read and write values in the store, and until now they could only answer `store unavailable`. Note what is *absent* from the new resources: no `create_before_destroy`. Two instances sharing one volume could corrupt data, so for stateful resources an overlap is the wrong choice.

```bash
diff -u main.tf stages/stage6a.tf
cp stages/stage6a.tf main.tf
```{{exec}}

Apply it:

```bash
terraform apply -auto-approve
```{{exec}}

The plan only adds resources. The app container is not touched: it finds the store by its name on the Docker network, the same way nginx finds `app`. That `main.tf` contains no reference from the app to the store is deliberate. Terraform applies `create_before_destroy` to everything that a create-before-destroy resource depends on, so a reference would quietly put the store under the very rule it must not have.

Store a value through the app, read it back the same way, and then look into the store itself:

```bash
curl -s -X PUT -d "do not lose me" localhost:8080/store/important
curl -s localhost:8080/store/important
docker exec store redis-cli get important
```{{exec}}

The app answers `stored important` and then returns the value, but it keeps nothing itself: the last line shows where the value really lives.

## What an accident looks like

Without protection, one command removes the volume. (`-target` is normally for debugging only; here it simulates a mistake. Terraform also destroys everything that depends on the volume, so the store container goes with it. And with `-auto-approve`, nothing asks whether you are sure.)

```bash
terraform destroy -target=docker_volume.data -auto-approve
```{{exec}}

The app is still running, but its data tier is gone:

```bash
curl -s localhost:8080/store/important
```{{exec}}

It answers `store unavailable`. Terraform can bring back the volume and the container, but not what was stored in them:

```bash
terraform apply -auto-approve
```{{exec}}

Ask for the value again, through the app and in the store itself:

```bash
curl -s localhost:8080/store/important
docker exec store redis-cli get important
```{{exec}}

The key is gone: the app answers `important is not set`, and `redis-cli` returns nothing. Terraform did exactly what it was asked to do.

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
```{{exec}}

Apply it:

```bash
terraform apply -auto-approve
```{{exec}}

The apply reports **no changes**: the guard is not a property of the volume, it exists only in your code. Store the value again:

```bash
curl -s -X PUT -d "do not lose me" localhost:8080/store/important
```{{exec}}

Now repeat the accident:

```bash
terraform destroy -target=docker_volume.data -auto-approve
```{{exec}}

Terraform now refuses with **Instance cannot be destroyed**, at *plan* time, before touching anything. Confirm the data survived:

```bash
curl -s localhost:8080/store/important
docker exec store redis-cli get important
```{{exec}}

**Limits of the guard:** `prevent_destroy` is a seatbelt, not a vault. It is only a flag in your code: whoever deletes the line (or the whole resource block) removes it, and it does not protect against actions outside Terraform. It catches *mistakes*, and it makes deliberate removal an explicit, reviewable code change.
