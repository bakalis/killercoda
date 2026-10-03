# Zero-downtime infrastructure changes with Terraform lifecycle rules

Killercoda scenario (backend image: `ubuntu`, no accounts needed).

```
index.json          scenario definition (intro, 7 steps, finish, assets)
intro.md / finish.md
setup/              background.sh installs Terraform and prepares the lab; foreground.sh waits for it
step1 … step7/      text.md (+ verify.sh for the "Check" button, steps 1–6)
assets/             uploaded to /root/assets: app, nginx config, traffic/score scripts, one main.tf per stage
```

Learner flow: `stage1.tf` (baseline) → bump version (outage) → `stage3a/3b.tf` (create_before_destroy) →
`stage4.tf` (health check + wait) → `stage5.tf` (replace_triggered_by) → `stage6a/6b.tf` (data store, prevent_destroy).

Pinned versions: Terraform 1.9.8 (`setup/background.sh`), `kreuzwerker/docker ~> 3.0`, nginx 1.27-alpine, python 3.12-alpine, redis 7-alpine.
