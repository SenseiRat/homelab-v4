job "rabbitmq" {
  datacenters = ["homelab"]
  type = "service"

  group "rabbitmq" {
    count = 3

    update {
      max_parallel = 1
    }

    network {
      port "rabbitmq-http" {
        to = 15672
      }
      port "rabbitmq-https" {
        to = 15671
      }
      port "rabbitmq-amqp" {
        to = 5672
      }
      port "rabbitmq-discovery" {
        to = 4369
      }
      port "rabbitmq-clustering" {
        to = 25672
      }
    }

    migrate {
      max_parallel = 1
      health_check = "checks"
      min_healthy_time = "5s"
      healthy_deadline = "30s"
    }

    task "rabbitmq" {
      driver = "docker"

      config {
        image = "rabbitmq:latest"
        ports = ["rabbitmq-http", "rabbitmq-https", "rabbitmq-amqp", "rabbitmq-discovery", "rabbitmq-clustering"]
      }

      env {
        RABBITMQ_ERLANG_COOKIE = "rabbitmq"
        RABBITMQ_DEFAULT_USER = "administrator"
        RABBITMQ_DEFAULT_PASS = "asdfb"

        CONSUL_HOST = "${attr.unique.network.ip-address}"
        CONSUL_SVC_PORT = "${NOMAD_HOST_PORT_amqp}"
        CONSUL_SVC_TAGS = "amqp"
      }

      service {
        name = "rabbitmq-http"
        provider = "nomad"
        port = "rabbitmq-http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.rabbitmq-http.rule=Host(`rabbitmq.senserat.com`)",
        ]
      }

      service {
        name = "rabbitmq-https"
        provider = "nomad"
        port = "rabbitmq-https"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.rabbitmq-https.tls=true",
          "traefik.http.routers.rabbitmq-https.rule=Host(`rabbitmq.senseirat.com`)",
          "traefik.http.routers.rabbitmq-https.tls.certresolver=letsencrypt",
          "traefik.http.services.rabbitmq-https.loadbalancer.server.port=15672",
        ]
      }
    }
  }
}
