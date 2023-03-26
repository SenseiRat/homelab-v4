job "authelia" {
  region      = "global"
  datacenters = ["homelab"]
  type        = "service"

  group "authelia" {
    count = 1

    volume "authelia-nomad" {
      type      = "csi"
      source    = "authelia-nomad"
      attachment_mode = "file-system"
      read_only = false
      access_mode = "multi-node-multi-writer"
    }

    network {
      port "authelia" {
        to = 80
        static = 8083
      }
    }

    task "authelia" {
      driver = "docker"

      volume_mount {
	volume = "authelia-nomad"
	destination = "/config"
	read_only = false
      }

      env {
	TZ = "America/Chicago"
        AUTHELIA_JWT_SECRET_FILE     = "/config/secrets/jwt"
        AUTHELIA_SESSION_SECRET_FILE = "/config/secrets/session"
      }

      config {
        image = "authelia/authelia:latest"
        ports = ["authelia"]
      }

      service {
        name = "authelia"
        port = "authelia"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.authelia.rule=Host(`auth.senseirat.com`)",
          "traefik.http.routers.authelia.tls.certResolver=letsencrypt",
        ]
      }
    }
  }
}
