job "mediawiki" {
  region = "global"
  datacenters = ["homelab"]
  type = "service"

  group "svc" {
    count = 1

    restart {
      attempts = 5
      delay = "15s"
    }

    network {
      port "mediawiki-http" {
        to = 80
      }
      port "mediawiki-https" {
        to = 443
      }
    }

    volume "mediawiki-data" {
      type = "csi"
      source = "mediawiki"
      attachment_mode = "file-system"
      read_only = false
      access_mode = "multi-node-multi-writer"
    }

    task "mediawiki" {
      driver = "docker"

      volume_mount {
        volume = "mediawiki-data"
        destination = "/var/www/mediawiki"
        read_only = false
      }

      config {
        image = "mediawiki:latest"
        ports = ["mediawiki-http", "mediawiki-https"]
      }

      resources {
        cpu = 200
        memory = 256
      }

      service {
        name = "mediawiki-http"
        provider = "nomad"
        port = "mediawiki-http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.mediawiki.rule=Host(`wiki.senseirat.com`)",
        ]
      }

      service {
        name = "mediawiki-https"
        provider = "nomad"
        port = "mediawiki-https"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.mediawiki-https.tls=true",
          "traefik.http.routers.mediawiki-https.rule=Host(`wiki.senseirat.com`)",
          "traefik.http.routers.mediawiki-https.tls.certresolver=letsencrypt",
          "traefik.http.services.mediawiki-https.loadbalancer.server.port=443",
        ]
      }
    }
  }
}
