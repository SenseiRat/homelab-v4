job "awx" {
  datacenters = ["homelab"]
  region = "global"
  type = "service"
 
  group "tower" {
    count = 1

    restart {
      attempts = 5
      delay = "30s"
      interval = "5m"
      mode = "fail"
    }

    task "awx" {
      driver = "docker"

      resources {
        cpu = 500
        memory = 1000
      }

      #artifact {
      #  source = "git:https://github.com/www-aiqu-no/nomad-job-awx.git//resources"
      #}

      env {
        AWX_ADMIN_USER = "awx"
        AWX_ADMIN_PASSWORD = "awx_secret"

        DATABASE_NAME = "awx"
        DATABASE_USER = "awx"
        DATABASE_PASSWORD = "awx"
        DATABASE_HOST = ""
        DATABASE_PORT = ""

        RABBITMQ_VHOST = "awx"
        RABBITMQ_USER = "awx"
        RABBITMQ_PASSWORD = "awx"
        RABBITMQ_HOST = ""
        RABBITMQ_PORT = ""

        # Can I use Redis instead?
        MEMCACHED_HOST = ""
        MEMCACHED_PORT = ""
      }

      config {
        image = "ansible/awx_task:latest"
        
