job "watchtower" {
  datacenters = ["homelab"]
  region = "global"
  type = "system"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert = "false"
    canary = 1
  }

  group "svc" {
    restart {
      attempts = 5
      interval = "3m"
      delay = "10s"
    }

    volume "docker-socket" {
      source = "/var/run/docker.sock"
    }

    task "watchtower" {
      driver = "docker"

      config {
        image = "containrrr/watchtower:armhf-latest"

        privileged = true
      }

      resources {
        cpu = 100
        memory = 32
      }
    }
  }
}