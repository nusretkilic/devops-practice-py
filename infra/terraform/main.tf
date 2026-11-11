terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
}

# Use only our named local kind context, not the current default context.
provider "kubernetes" {
  config_path    = pathexpand("~/.kube/config")
  config_context = "kind-devops-practice"
}

variable "image" {
  description = "Published multi-platform image pinned to its immutable index digest."
  type        = string
  default     = "ghcr.io/nusretkilic/devops-practice-py@sha256:a2ce5250d4c5a9fb5faedf1fc12a8678e9c327197906ceffa6d1a46b7626cf4f"

  validation {
    condition     = can(regex("^ghcr\\.io/nusretkilic/devops-practice-py@sha256:[0-9a-f]{64}$", var.image))
    error_message = "Use this repository's image with a full sha256 digest, not a mutable tag."
  }
}

variable "image_pull_secret_name" {
  description = "Optional Kubernetes registry pull secret for private images."
  type        = string
  default     = null
}

locals {
  app_name = "devops-practice"
  labels = {
    app = "devops-practice"
  }
}

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = local.app_name
  }
}

resource "kubernetes_deployment_v1" "app" {
  metadata {
    name      = local.app_name
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = local.labels
  }

  wait_for_rollout = true

  spec {
    replicas                  = 1
    revision_history_limit    = 3
    progress_deadline_seconds = 180

    selector {
      match_labels = local.labels
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        automount_service_account_token = false
        host_network                    = false

        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secret_name == null ? [] : [var.image_pull_secret_name]
          content {
            name = image_pull_secrets.value
          }
        }

        security_context {
          run_as_non_root = true
          run_as_user     = 10001
          run_as_group    = 10001

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name              = local.app_name
          image             = var.image
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 8000
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true

            capabilities {
              drop = ["ALL"]
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = "http"
            }
            initial_delay_seconds = 3
            period_seconds        = 5
            timeout_seconds       = 2
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = "http"
            }
            initial_delay_seconds = 15
            period_seconds        = 10
            timeout_seconds       = 2
            failure_threshold     = 3
          }
        }
      }
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
  }
}

# Cluster-internal access only: no NodePort or LoadBalancer.
resource "kubernetes_service_v1" "app" {
  metadata {
    name      = local.app_name
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  spec {
    type     = "ClusterIP"
    selector = local.labels

    port {
      name        = "http"
      port        = 8000
      target_port = "http"
    }
  }
}

output "namespace" {
  value = kubernetes_namespace_v1.app.metadata[0].name
}

output "deployed_image" {
  value = var.image
}
