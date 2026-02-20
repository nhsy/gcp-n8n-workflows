output "n8n_url" {
  description = "The URL of the n8n Cloud Run service"
  value       = google_cloud_run_v2_service.n8n_service.uri
}

output "service_account_email" {
  description = "The email of the n8n Service Account"
  value       = google_service_account.n8n_sa.email
}

output "db_instance_connection_name" {
  description = "The connection name of the Cloud SQL instance"
  value       = google_sql_database_instance.n8n_db_instance.connection_name
}
