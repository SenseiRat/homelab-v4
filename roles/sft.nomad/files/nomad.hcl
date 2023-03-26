data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"
datacenter = "homelab"

server {
    enabled = true
    bootstrap_expect = 3
}

client {
    enabled = true
}