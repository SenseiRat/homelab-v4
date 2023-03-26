job "pgadmin" {
  region = "global"
  datacenters = ["homelab"]
  type = "service"

  group "pgadmin" {
    count = 1

    restart {
      attempts = 5
      delay = "15s"
    }

    network {
      port "pgadmin-http" {
        to = 80
      }
      port "pgadmin-https" {
        to = 443
      }
    }

    task "pgadmin" {
      driver = "docker"

      config {
        image = "dpage/pgadmin4:latest"
        ports = ["pgadmin-http", "pgadmin-https"]

        volumes = [
          "local/servers.json:/servers.json",
          "local/servers.passfile:/root/.pgpass"
        ]
      }

      template {
        perms = "600"
        change_mode = "noop"
        destination = "local/servers.passfile"
        data = <<EOH
postgres.service.consul:5432:postgres:postgres:postgres
EOH
      }

      template {
        change_mode = "noop"
        destination = "local/servers.json"
        data = <<EOH
{
  "Servers": {
    "1": {
      "Name": "Postgres",
      "Group": "Server Group 1",
      "Port": 5432,
      "Username": "postgres",
      "Passfile": "/root/.pgpass",
      "Host": "postgres.senseirat.com",
      "SSLMode": "disable",
      "MaintenanceDB": "postgres"
    }
  }
}
EOH
      }

      env {
        PGADMIN_DEFAULT_EMAIL = "homelab@senseirat.com"
        PGADMIN_DEFAULT_PASSWORD = "pgadmin"
        PGADMIN_LISTEN_ADDRESS = "0.0.0.0"
        PGADMIN_LISTEN_PORT = "80"
        PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION = "False"
        PGADMIN_SERVER_JSON_FILE = "/servers.json"
        #PGADMIN_ENABLE_TLS = "True"
      }

      resources {
        cpu = 200
        memory = 256
      }

      service {
        name = "pgadmin-http"
        provider = "nomad"
        port = "pgadmin-http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.pgadmin.rule=Host(`pgadmin.senseirat.com`)",
        ]
      }

      service {
        name = "pgadmin-https"
        provider = "nomad"
        port = "pgadmin-https"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.pgadmin-https.tls=true",
          "traefik.http.routers.pgadmin-https.rule=Host(`pgadmin.senseirat.com`)",
          "traefik.http.routers.pgadmin-https.tls.certresolver=letsencrypt",
          "traefik.http.services.pgadmin-https.loadbalancer.server.port=443",
        ]
      }
    }
  }
}
