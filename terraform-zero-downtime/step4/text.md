# Step 4: Fix readiness with a health check

**Goal:** make Terraform wait until the new container is actually ready before it removes the old one.

```diff
+  healthcheck {
+    test     = ["CMD", "wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8080/health"]
+    interval = "1s"
+    timeout  = "2s"
+    retries  = 3
+  }
+
+  wait         = true
+  wait_timeout = 60
```

- `healthcheck` tells **Docker** how to decide the app is ready.
- `wait = true` tells **Terraform** to block until Docker reports *healthy*. Combined with `create_before_destroy`, the old container is only removed after the new one passes its check.

```
 old  ██████████████████████░░░░░░░░
 new  ░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒█████████
                           └ switch, no gap
```

```bash
diff -u main.tf stages/stage4.tf
cp stages/stage4.tf main.tf
echo 'app_version = "4.0"' > terraform.tfvars
terraform apply -auto-approve
score "step 4: + health check"
```{{exec}}

Notice that `apply` now takes a few seconds longer: that is Terraform waiting. The failure count should be **0 or close to it**.

If you still see one to three failures, that is a real limit, not a mistake: a request that was already in flight to the old container when it stopped can still fail. Terraform controls *ordering*; it does not drain connections. We come back to this in the last step.
