terraform {
  required_version = ">= 1.5"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

variable "app_version" {
  type    = string
  default = "1.0"
}

resource "docker_network" "lab" {
  name = "lab"
}

# ---- Load balancer (only component with a published port) ----
resource "docker_image" "nginx" {
  name         = "nginx:1.27-alpine"
  keep_locally = true
}

resource "docker_container" "lb" {
  name  = "lb"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 8080
  }

  volumes {
    host_path      = abspath("${path.module}/nginx.conf")
    container_path = "/etc/nginx/conf.d/default.conf"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.lab.name
  }
}

# ---- App image: built by Terraform, tagged with the version ----
resource "docker_image" "app" {
  name = "demo-app:${var.app_version}"

  build {
    context    = "${path.module}/app"
    build_args = { VERSION = var.app_version }
    tag        = ["demo-app:${var.app_version}"]
  }

  keep_locally = true
}


# ---- App container (stateless) ----
resource "docker_container" "app" {
  name  = "app"
  image = docker_image.app.image_id

  networks_advanced {
    name    = docker_network.lab.name
    aliases = ["app"]
  }

  volumes {
    host_path      = abspath("${path.module}/config")
    container_path = "/config"
    read_only      = true
  }
}
