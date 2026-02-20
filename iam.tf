resource "google_service_account" "n8n_sa" {
  account_id   = "n8n-service-account"
  display_name = "n8n Cloud Run Service Account"
  depends_on   = [google_project_service.enabled_apis]
}

# Grant Cloud SQL Client Access
resource "google_project_iam_member" "n8n_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.n8n_sa.email}"
}

# Grant Vertex AI User Access (for the workflow prompt)
resource "google_project_iam_member" "n8n_vertex_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.n8n_sa.email}"
}
