resource "google_cloud_run_v2_service" "n8n_service" {
  name     = "n8n"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account  = google_service_account.n8n_sa.email
    session_affinity = true
    timeout          = "3600s"

    scaling {
      min_instance_count = 1
      max_instance_count = 1
    }

    containers {
      image = "n8nio/n8n:latest"

      # Overriding default entrypoint to ensure DB proxy starts
      command = ["/bin/sh"]
      args    = ["-c", "sleep 5;n8n start"]

      ports {
        container_port = 5678
      }

      resources {
        limits = {
          memory = "2Gi"
        }
        cpu_idle = false # Avoid CPU throttling for background tasks
      }

      env {
        name  = "N8N_PORT"
        value = "5678"
      }
      env {
        name  = "N8N_PROTOCOL"
        value = "https"
      }
      env {
        name  = "DB_TYPE"
        value = "postgresdb"
      }
      env {
        name  = "DB_POSTGRESDB_DATABASE"
        value = "n8n"
      }
      env {
        name  = "DB_POSTGRESDB_USER"
        value = "n8n-user"
      }
      env {
        name = "DB_POSTGRESDB_HOST"
        # Cloud Run connects to Cloud SQL via unix sockets when volumes are configured
        value = "/cloudsql/${google_sql_database_instance.n8n_db_instance.connection_name}"
      }
      env {
        name  = "DB_POSTGRESDB_PORT"
        value = "5432"
      }
      env {
        name  = "DB_POSTGRESDB_SCHEMA"
        value = "public"
      }
      env {
        name  = "GENERIC_TIMEZONE"
        value = "UTC"
      }
      env {
        name  = "QUEUE_HEALTH_CHECK_ACTIVE"
        value = "true"
      }
      dynamic "env" {
        for_each = var.n8n_url != "" ? [1] : []
        content {
          name  = "N8N_HOST"
          value = local.n8n_host
        }
      }
      dynamic "env" {
        for_each = var.n8n_url != "" ? [1] : []
        content {
          name  = "WEBHOOK_URL"
          value = var.n8n_url
        }
      }

      # Secrets
      env {
        name = "DB_POSTGRESDB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.n8n_db_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "N8N_ENCRYPTION_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.n8n_encryption_key.secret_id
            version = "latest"
          }
        }
      }

      # Mount Cloud SQL proxy socket
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.n8n_db_instance.connection_name]
      }
    }
  }

  depends_on = [google_project_service.enabled_apis]
}

# Allow unauthenticated invocation (optional, usually required to access the n8n web UI publicly)
resource "google_cloud_run_v2_service_iam_member" "n8n_public_access" {
  project  = google_cloud_run_v2_service.n8n_service.project
  location = google_cloud_run_v2_service.n8n_service.location
  name     = google_cloud_run_v2_service.n8n_service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
