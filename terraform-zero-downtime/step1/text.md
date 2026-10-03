# Step 1: Deploy the baseline and start measuring

**Goal:** get a working stack from code and establish a clean "no failures" baseline.

Look at the configuration. It declares a network, the nginx load balancer, an app image built from `app/`, and one app container:

```bash
cd /root/lab
cat main.tf
```{{exec}}

Two things to notice:

- `image = docker_image.app.image_id`: the container depends on the image, so changing the image *forces a replacement* of the container. That is the event we will study.
- The app container has no `lifecycle` block, so Terraform's **defaults** apply.

Create everything. `init` downloads the Docker provider, `apply` builds the image and starts the containers:

```bash
terraform init
terraform apply -auto-approve
```{{exec}}

The app needs about 5 seconds to boot. Check that it answers through the load balancer:

```bash
sleep 6; curl -s localhost:8080
```{{exec}}

You should see `version=1.0 banner=banner v1`. Now set the measurement marker. Everything from this moment on is counted:

```bash
score start
```{{exec}}

**Why this matters:** every later step is compared to this baseline. Without a measurement, "zero downtime" is only a claim.

Optional: open a second terminal tab and run `monitor` to watch OK/FAILED requests per second live.
