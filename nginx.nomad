job "nginx" {
  datacenters = ["hc_demo"]

  type = "service"

  update {
    max_parallel      = 3
    min_healthy_time  = "10s"
    healthy_deadline  = "3m"
    progress_deadline = "10m"
    auto_revert       = false
    canary            = 0
  }

  migrate {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "5m"
  }

  group "web" {
    count = 23

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    network {
      port "http" { to = 80 }
    }

    task "server" {
      driver = "docker"

      config {
        image = "nginx:alpine"
        volumes = [
          # Use relative paths to rebind paths already in the allocation dir
          "html:/usr/share/nginx/html"
        ]
        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 64

      }

      service {
        name = "nginx"
        tags = ["urlprefix-/"]
        port = "http"
        check {
          name           = "alive"
          type           = "tcp"
          interval       = "3s"
          timeout        = "2s"
          initial_status = "critical"
        }
      }

      template {
        data = <<EORC
<h1>I'm an nginx!</h1>
nomad_allocation_id:  {{ env "NOMAD_ALLOC_INDEX" }} </p>
bind_port:            {{ env "NOMAD_ADDR_http" }} </p>
node_id:              {{ env "node.unique.id" }} </p>
node_name:            {{ env "node.unique.name" }} </p>
aws_as:               {{ env "attr.platform.aws.placement.availability-zone" }} </p>
aws_instance_id:      {{ env "attr.unique.platform.aws.instance-id" }} </p>

kv_magic:  {{ keyOrDefault "demo" "No magic here"}}
EORC

        destination   = "html/index.html"
        change_mode   = "noop"
      }
    }
  }
}
