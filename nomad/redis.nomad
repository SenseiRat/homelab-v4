job "redis" {
  datacenters = ["homelab"]
  region = "global"
  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert = "false"
    canary = 1
  }

  group "cache" {
    count = 1

    restart {
      attempts = 5
      interval = "3m"
      delay = "10s"
    }

    network {
      port "redis-db" {
        to = 6379
      }
    }

    ephemeral_disk {
      size = 300
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:latest"
        ports = ["redis-db"]
      }

      resources {
        cpu = 500
        memory = 256
      }

      service {
        name = "global-redis-check"
        provider = "nomad"
        port = "redis-db"

        check {
          name = "alive"
          type = "tcp"
          interval = "10s"
          timeout = "2s"
        }

        tags = [
          "traefik.enable=true",
          "traefik.tcp.routers.redis.entrypoints=redis",
          "traefik.tcp.routers.redis.rule=HostSNI(`*`)",
        ]
      }
    }
  }
}
