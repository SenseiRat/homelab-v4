job "drone" {
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
      port "drone-http" {
        to = 80
      }
      port "drone-https" {
        to = 443
      }
    }

    task "drone" {
      driver = "docker"

      config {
        image = "drone/drone:latest"
        ports = ["drone-http", "drone-https"]
      }

      env = {
        DRONE_GITEA_CLIENT_ID = ""
        DRONE_GITEA_CLIENT_SECRET = ""
        DRONE_GITEA_SERVER = "https:/git.senseirat.com"
        #DRONE_GIT_ALWAYS_AUTH = "True|False"
        #DRONE_RPC_SECRET = ""
        DRONE_SERVER_HOST = "drone.senseirat.com"
        DRONE_SERVER_PROTO = "http"
      }

      resources {
        cpu = 200
        memory = 256
      }

      service {
        name = "drone-http"
        provider = "nomad"
        port = "drone-http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.drone.rule=Host(`drone.senseirat.com`)",
        ]
      }

      service {
        name = "drone-https"
        provider = "nomad"
        port = "drone-https"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.drone-https.tls=true",
          "traefik.http.routers.drone-https.rule=Host(`drone.senseirat.com`)",
          "traefik.http.routers.drone-https.tls.certresolver=letsencrypt",
          "traefik.http.services.drone-https.loadbalancer.server.port=443",
        ]
      }
    }
  }
}
