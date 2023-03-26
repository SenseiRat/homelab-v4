job "pihole" {
  region = "global"
  datacenters = ["homelab"]
  type = "service"

  group "pihole" {
    count = 1

    restart {
      attempts = 5
      delay = "15s"
    }

    network {
      port "pihole-http" {
        to = 80
      }
      port "pihole-https" {
        to = 443
      }
      port "pihole-dns" {
        to = 53
      }
    }

    volume "pihole" {
      type = "csi"
      source = "pihole"
      attachment_mode = "file-system"
      read_only = false
      access_mode = "multi-node-multi-writer"
    }

    volume "dnsmasq" {
      type = "csi"
      source = "dnsmasq"
      attachment_mode = "file-system"
      read_only = false
      access_mode = "multi-node-multi-writer"
    }

    task "pihole" {
      driver = "docker"

      volume_mount {
        volume = "pihole"
        destination = "/etc/pihole"
        read_only = false
      }

      volume_mount {
        volume = "dnsmasq"
        destination = "/etc/dnsmasq.d"
        read_only = false
      }

      config {
        image = "pihole/pihole:latest"
        ports = ["pihole-http", "pihole-https", "pihole-dns"]

        dns_servers = [
          "127.0.0.1",
          "8.8.8.8",
          "8.8.4.4",
        ]
      }

      env {
        TZ = "America/Chicago"
        WEBPASSWORD = "asdfb"
        INTERFACE = "eth0"
        PIHOLE_DOMAIN = "senseirat.com"
        WEBTHEME = "dark"
        PIHOLE_DNS_ = "8.8.8.8;8.8.4.4"
        DNSMASQ_USER = "root"
      }

      resources {
        cpu = 100
        memory = 128
        }
      }

      service {
        name = "pihole-http"
        provider = "nomad"
        port = "pihole-http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.pihole.rule=Host(`pihole.senseirat.com`)",
        ]
      }

      service {
        name = "pihole-https"
        provider = "nomad"
        port = "pihole-https"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.pihole-https.tls=true",
          "traefik.http.routers.pihole-https.rule=Host(`pihole.senseirat.com`)",
          "traefik.http.routers.pihole-https.tls.certresolver=letsencrypt",
          "traefik.http.services.pihole-https.loadbalancer.server.port=443",
        ]
      }

      service {
        name = "pihole-dns-udp"
        provider = "nomad"
        port = "pihole-dns"

        tags = [
          "traefik.enable=true",

          "traefik.udp.routers.pihole-dns-udp.entrypoints=dns-udp",
        ]
      }

      service {
        name = "pihole-dns-tcp"
        provider = "nomad"
        port = "pihole-dns"

        tags = [
          "traefik.enable=true",
          
          "traefik.tcp.routers.pihole-dns-tcp.entrypoints=dns-tcp",
          "traefik.tcp.routers.pihole-dns-tcp.rule=HostSNI(`*`)",
        ]
      }
    }
  }
