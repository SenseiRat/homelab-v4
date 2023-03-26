job "plugin-nfs-controller" {
  datacenters = ["homelab"]
  type = "system"
  group "controller" {
    task "plugin" {
      driver = "docker"

      config {
        image = "registry.k8s.io/sig-storage/nfsplugin:v4.1.0"
        args = [
          "--v=5",
          "--nodeid=${attr.unique.hostname}",
          "--endpoint=unix:///csi/csi.sock",
          "--drivername=nfs.csi.k8s.io"
        ]

        privileged = true
      }

      csi_plugin {
        id = "nfsofficial"
        type = "controller"
        mount_dir = "/csi"
      }

      resources {
        memory = 32
        cpu = 100
      }
    }
  }
}