job "vault" {
  datacenters = ["homelab"]
  type = "service"

  group "vault" {
    count = 1

    network {
      port "vault-ui" {
        to = 8200
      }
    }

    task "vault" {
      driver = "raw_exec"

      resources {
        cpu = 500
        memory = 512
      }

      config {
        command = "/usr/bin/vault"
        args = ["server", "-config=/etc/vault.d/vault.hcl"]
      }

      service {
        name = "vault-http"
        provider = "nomad"
        port = "vault-ui"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.vault.rule=Host(`vault.senseirat.com`)",
        ]
      }

      service {
        name = "vault-https"
        provider = "nomad"
        port = "vault-ui"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.vault-https.tls=true",
          "traefik.http.routers.vault-https.rule=Host(`vault.senseirat.com`)",
          "traefik.http.routers.vault-https.tls.certresolver=letsencrypt",
          "traefik.http.services.vault-https.loadbalancer.server.port=8200",
        ]
      }
    }
  }
}
