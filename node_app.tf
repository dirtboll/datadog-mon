resource "kubernetes_secret" "node_app" {
  metadata {
    name = "node-app"
  }
  data = {
    DATABASE_URL = "postgresql://${aws_db_instance.default.username}:${aws_db_instance.default.password}@${aws_db_instance.default.endpoint}/postgres"
  }
}

resource "kubernetes_deployment" "node_app" {
  metadata {
    name = "node-app"
    annotations = {
      "internal.dd.datadoghq.com/node-app.detected_langs" = "node"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "node-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "node-app"
          "admission.datadoghq.com/enabled" = "true"
          "tags.datadoghq.com/env" = "production"
          "tags.datadoghq.com/service" = "todo-app"
          "tags.datadoghq.com/version" = "v0.0.1"
        }
        annotations = {
          "admission.datadoghq.com/js-lib.version" = "5"
        }
      }
      spec {
        container {
          name = "node-app"
          image = "gdaditya/node-todo:v0.0.1"
          env_from {
            secret_ref {
              name = kubernetes_secret.node_app.metadata[0].name
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "node_app" {
  metadata {
    name = "node-app"
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = "node-app"
    }
    port {
      port = 80
      target_port = 3000
    }
  }
}