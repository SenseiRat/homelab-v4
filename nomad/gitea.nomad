job "gitea" {
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
      port "gitea-http" {
        to = 3000
      }
      port "gitea-https" {
        to = 443
      }
      port "gitea-ssh" {
        to = 22
      }
    }

    volume "gitea-data" {
      type = "csi"
      source = "gitea"
      attachment_mode = "file-system"
      read_only = false
      access_mode = "multi-node-single-writer"
    }

    task "gitea" {
      driver = "docker"

      volume_mount {
        volume = "gitea-data"
        destination = "/data"
        read_only = false
      }

      config {
        image = "gitea/gitea:latest"
        ports = ["gitea-http", "gitea-https", "gitea-ssh"]
      }

      env = {
        APP_NAME = "Gitea: Git with a cup of tea"
        RUN_MODE = "prod"
        SSH_DOMAIN = "git.senseirat.com"
        SSH_PORT = "22"
        ROOT_URL = "https://git.senseirat.com"
        USER_UID = "1000"
        USER_GID = "1000"
        DB_TYPE = "postgres"
        DB_HOST = "postgres.senseirat.com"
        DB_NAME = "gitea"
        DB_USER = "gitea"
        DB_PASSWD = "gitea"
      }

      resources {
        cpu = 200
        memory = 256
      }

      service {
        name = "gitea-http"
        provider = "nomad"
        port = "gitea-http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.gitea.rule=Host(`git.senseirat.com`)",
        ]
      }

      service {
        name = "gitea-https"
        provider = "nomad"
        port = "gitea-https"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.gitea-https.tls=true",
          "traefik.http.routers.gitea-https.rule=Host(`git.senseirat.com`)",
          "traefik.http.routers.gitea-https.tls.certresolver=letsencrypt",
          "traefik.http.services.gitea-https.loadbalancer.server.port=443",
        ]
      }

      service {
        name = "gitea-ssh"
        provider = "nomad"
        port = "gitea-ssh"

        tags = [
          "traefik.enable=true",
          "traefik.tcp.routers.gitea-ssh.entrypoints=git-ssh",
          "traefik.tcp.routers.gitea-ssh.rule=HostSNI(`*`)",
        ]
      }
    }
  }
}
