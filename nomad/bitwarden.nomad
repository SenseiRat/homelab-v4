job "bitwarden" {
  region = "global"
  datacenters = ["homelab"]
  type = "service"

  group "bitwarden" {
    count = 1

    restart {
      attempts = 5
      delay = "15s"
    }

    network {
      port "bitwarden-http" {
        to = 80
      }
      port "bitwarden-https" {
        to = 443
      }
    }

    volume "bitwarden" {
      type = "csi"
      source = "bitwarden"
      attachment_mode = "file-system"
      read_only = false
      access_mode = "multi-node-multi-writer"
    }

    task "bitwarden" {
      driver = "docker"

      volume_mount {
        volume = "bitwarden"
        destination = "/data"
        read_only = false
      }

      config {
        image = "vaultwarden/server"
        ports = ["bitwarden-http", "bitwarden-https"]
      }

      resources {
        cpu = 100
        memory = 1024
        }
      }

      service {
        name = "bitwarden-http"
        provider = "nomad"
        port = "bitwarden-http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.bitwarden.rule=Host(`bitwarden.senseirat.com`)",
        ]
      }

      service {
        name = "bitwarden-https"
        provider = "nomad"
        port = "bitwarden-https"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.bitwarden-https.tls=true",
          "traefik.http.routers.bitwarden-https.rule=Host(`bitwarden.senseirat.com`)",
          "traefik.http.routers.bitwarden-https.tls.certresolver=letsencrypt",
          "traefik.http.services.bitwarden-https.loadbalancer.server.port=443",
        ]
      }
    }
  }
