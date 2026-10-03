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

Initialise the working directory. `init` downloads the Docker provider:

```bash
terraform init
```{{exec}}

Now create everything. A plain `terraform apply` prints its plan and then stops at `Enter a value:`; nothing is changed until you type `yes`. The flag `-auto-approve` skips that question, so Terraform plans and applies in one go. This tutorial uses it for every apply and destroy, so that each of them runs with a single click. Wherever the plan itself is the lesson, we run `terraform plan` first and read it. On real infrastructure that question is your last chance to review a change: keep it, or apply a plan that was saved and reviewed beforehand.

`apply` builds the image and starts the containers:

```bash
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

## Optional: watch the traffic live

Open a second terminal tab and run `monitor` there. It shows the traffic as one line per *streak*:

```text
  SINCE        FOR     OK  FAILED  VERSIONS
> 14:01:40     48s    431       0  v1.0
```

While every request is answered by the same version, the monitor keeps updating that one line (`>` marks the line that is still growing). It starts a new line only when something changes: other versions start answering, or requests fail. Seconds with failed requests are never merged. Each one gets its own line, so you can follow an outage second by second.

Leave it running, and switch back to the first tab before you click the next command.
