job "faas-idler" {
  datacenters = ["dc1"]

  type = "system"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "faas-idler" {
    count = 1

    restart {
      attempts = 20
      interval = "380s"
      delay    = "5s"
      mode     = "delay"
    }

    task "faas-idler" {
      driver = "docker"

      template {
        env = true
        destination   = "secrets/faas-idler.env"

        data = <<EOH
gateway_url="http://{{ env "NOMAD_IP_http" }}:8080/"
{{ range service "prometheus" }}
prometheus_host="{{ .Address }}"
prometheus_port="{{ .Port }}"{{ end }}
inactivity_duration="5m"
reconcile_interval="30s"
write_debug=true
EOH
      }

      config {
        image = "openfaas/faas-idler:latest"

        args = [
          "-dry-run=false"
        ]
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 50 # MB

        network {
          mbits = 10

          port "http" {}
        }
      }

      service {
        port = "http"
        name = "faas-idler"
        tags = ["faas-idler"]
      }

    }
  }
}