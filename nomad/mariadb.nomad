job "mariadb" {
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
      port "mariadb-db" {
        to = 3306
      }
    }

    volume "mariadb" {
      type = "csi"
      source = "mariadb"
      attachment_mode = "file-system"
      read_only = false
      access_mode = "single-node-writer"
    }

    task "mariadb" {
      driver = "docker"

      volume_mount {
        volume = "mariadb"
        destination = "/var/lib/mysql"
        read_only = false
      }

      config {
        image = "mariadb:latest"
        ports = ["mariadb-db"]
      }

      env {
        MARIADB_USER = "mariadb"
        MARIADB_PASSWORD = "mariadb"
        MARIADB_ROOT_PASSWORD = "mariadb"
      } 

      resources {
        cpu = 200
        memory = 128
      }

      service {
        name = "mariadb"
        provider = "nomad"
        port = "mariadb-db"

        tags = [
          "traefik.enable=true",
          "traefik.tcp.routers.mariadb.entrypoints=mariadb",
          "traefik.tcp.routers.mariadb.rule=HostSNI(`*`)",
        ]
      }
    }
  }
}
