job "postgres" {
  region = "global"
  datacenters = ["homelab"]
  type = "service"

  group "svc" {
    count = 1

    restart {
      attempts = 5
      delay = "30s"
    }

    network {
      port "postgres-db" {
        to = 5432
      }
    }

    volume "postgres" {
      type = "csi"
      source = "postgres"
      attachment_mode = "file-system"
      read_only = false
      access_mode = "single-node-writer"
    }

    task "postgres" {
      driver = "docker"

      volume_mount {
        volume = "postgres"
        destination = "/var/lib/postgresql/data"
        read_only = false
      }

      config {
        image = "postgres:latest"
        ports = ["postgres-db"]
      }

      env {
        POSTGRES_USER = "postgres"
        POSTGRES_PASSWORD = "postgres"
      } 

      resources {
        cpu = 200
        memory = 128
      }

      service {
        name = "postgres"
        provider = "nomad"
        port = "postgres-db"

        tags = [
          "traefik.enable=true",
          "traefik.tcp.routers.postgres.entrypoints=postgres-db",
          "traefik.tcp.routers.postgres.rule=HostSNI(`*`)",
        ]
      }
    }
  }
}
