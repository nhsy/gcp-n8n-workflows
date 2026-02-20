resource "google_sql_database_instance" "n8n_db_instance" {
  name             = "n8n-db"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = "db-g1-small"
  }
  depends_on = [google_project_service.enabled_apis]
}

resource "google_sql_database" "n8n_db" {
  name     = "n8n"
  instance = google_sql_database_instance.n8n_db_instance.name
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "google_sql_user" "n8n_db_user" {
  name     = "n8n-user"
  instance = google_sql_database_instance.n8n_db_instance.name
  password = random_password.db_password.result
}
