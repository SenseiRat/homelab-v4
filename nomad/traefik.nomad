job "traefik" {
  region = "global"
  datacenters = ["homelab"]
  type = "service"

  group "traefik" {
    count = 3

    constraint {
      operator = "distinct_hosts"
      value = "true"
    }

    network {
      port "web" {
        static = 80
      }
      port "websecure" {
        static = 443
      }
      port "admin" {
        static = 8080
      }
      port "git_ssh" {
        static = 2222
      }
      port "dns" {
        static = 53
      }
      port "postgres" {
        static = 5432
      }
      port "redis" {
        static = 6379
      }
    }

    service {
      name = "traefik-http"
      provider = "nomad"
      port = "web"

      tags = [
        "traefik.enable=true",
      ]
    }

    volume "letsencrypt" {
      type = "csi"
      source = "letsencrypt"
      attachment_mode = "file-system"
      read_only = false
      access_mode = "multi-node-multi-writer"
    }

    volume "traefik-config" {
      type = "csi"
      source = "traefik-config"
      attachment_mode = "file-system"
      read_only = true
      access_mode = "multi-node-reader-only"
    }

    task "traefik" {
      driver = "docker"

      resources {
        cpu = 100
        memory = 512
      }

      volume_mount {
        volume = "letsencrypt"
        destination = "/opt/acme"
        read_only = false
      }

      volume_mount {
        volume = "traefik-config"
        destination = "/config"
        read_only = true
      }

      env {
        CF_DNS_API_TOKEN = "FNMa4fnLZPJ43p26PB1xvZ3hL90lKgTB11_9txbJ"
      }

      config {
        image = "traefik:latest"
        ports = ["admin", "web", "websecure", "dns", "postgres", "git_ssh", "redis"]

        args = [
          # API
          "--api.dashboard=true",
          "--api.insecure=true",
          
          # Traefik Admin Panel
          "--entrypoints.traefik.address=:${NOMAD_PORT_admin}",

          # HTTP
          "--entrypoints.web.address=:${NOMAD_PORT_web}",

          # HTTP to HTTPS
          "--entrypoints.web.http.redirections.entrypoint.to=websecure",
          "--entrypoints.web.http.redirections.entrypoint.scheme=https",

          # HTTPS
          "--entrypoints.websecure.address=:${NOMAD_PORT_websecure}",
          "--certificatesresolvers.letsencrypt=true",
          "--certificatesresolvers.letsencrypt.acme.email=homelab@senseirat.com",
          "--certificatesresolvers.letsencrypt.acme.storage=/opt/acme/acme.json",
          "--certificatesresolvers.letsencrypt.acme.httpchallenge=false",
          "--certificatesresolvers.letsencrypt.acme.dnschallenge=true",
          "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare",
          "--certificatesresolvers.letsencrypt.acme.dnschallenge.delaybeforecheck=15",
          "--certificatesresolvers.letsencrypt.acme.caserver=https://acme-v02.api.letsencrypt.org/directory",

          # DNS
          "--entrypoints.dns-tcp.address=:${NOMAD_PORT_dns}",
          "--entrypoints.dns-udp.address=:${NOMAD_PORT_dns}/udp",

          # Database
          "--entrypoints.postgres-db.address=:${NOMAD_PORT_postgres}",

          # SSH
          "--entrypoints.git-ssh.address=:${NOMAD_PORT_git_ssh}",

          # Redis
          "--entrypoints.redis.address=:${NOMAD_PORT_redis}",

          # Providers
          "--providers.nomad=true",
          "--providers.nomad.endpoint.address=http://${NOMAD_IP_web}:4646",
          "--providers.nomad.endpoint.endpointwaittime=5",
          #"--providers.consul.endpoints=192.168.1.201:8500",
          #"--providers.consul.rootkey=traefik",
          #"--providers.consulcatalog=true",
          #"--providers.consulcatalog.prefix=traefik",
          #"--providers.consulcatalog.exposedbydefault=false",
          #"--providers.consulcatalog.endpoint.address=192.168.1.201:8500",
          #"--providers.consulcatalog.endpoint.datacenter=homelab",
        ]
      }

      service {
        name = "traefik-dashboard"
        port = "websecure"
        provider = "nomad"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.traefik-dashboard.rule=Host(`traefik.senseirat.com`)",
          "traefik.http.routers.traefik-dashboard.tls=true",
          "traefik.http.routers.traefik-dashboard.tls.certresolver=letsencrypt",
          "traefik.http.services.traefik-dashboard.loadbalancer.server.port=8080",
        ]
      }

      service {
        name = "nomad-dashboard"
        port = "websecure"
        provider = "nomad"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.nomad-dashboard.rule=Host(`nomad.senseirat.com`)",
          "traefik.http.routers.nomad-dashboard.tls=true",
          "traefik.http.routers.nomad-dashboard.tls.certresolver=letsencrypt",
          "traefik.http.services.nomad-dashboard.loadbalancer.server.port=4646",
        ]
      }

      service {
        name = "consul-dashboard"
        port = "websecure"
        provider = "nomad"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.consul-dashboard.rule=Host(`consul.senseirat.com`)",
          "traefik.http.routers.consul-dashboard.tls=true",
          "traefik.http.routers.consul-dashboard.tls.certresolver=letsencrypt",
          "traefik.http.services.consul-dashboard.loadbalancer.server.port=8500",
        ]
      }
    }
  }
}
