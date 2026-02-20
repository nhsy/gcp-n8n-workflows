# Solution Design: n8n on Google Cloud Run POC

## 1. Architecture Overview

This proof of concept (POC) provisions a highly available and secure instance of [n8n](https://n8n.io/) operating entirely within Google Cloud.

* **Google Cloud Run:** A serverless environment running the official `n8nio/n8n:latest` Docker image.
* **Google Cloud SQL (PostgreSQL):** A fully managed PostgreSQL instance acting as the persistent storage layer for n8n executions, credentials, and configurations.
* **Google Secret Manager:** Securely stores sensitive configuration data including the PostgreSQL database password and the n8n encryption key.
* **IAM Service Account:** A dedicated, minimal-privilege Service Account attached to the Cloud Run service. This provides access to Cloud SQL, Secret Manager, and Vertex AI.

## 2. Terraform Implementation

The following Terraform snippets detail the provisioning of the required GCP infrastructure without reliance on the `gcloud` CLI.

### 2.1 Enable Project Services

Ensure that all required APIs are active before provisioning resources.

```terraform
locals {
  services = [
    "sqladmin.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "aiplatform.googleapis.com",
    "iam.googleapis.com"
  ]
}

resource "google_project_service" "enabled_apis" {
  for_each           = toset(local.services)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
```

### 2.2 Service Account & IAM Bindings

Create the execution identity for the Cloud Run service.

```terraform
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
```

### 2.3 Cloud SQL (PostgreSQL)

Provision the managed database.

```terraform
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
```

### 2.4 Secret Manager

Store sensitive data securely.

```terraform
# DB Password Secret
resource "google_secret_manager_secret" "n8n_db_password" {
  secret_id = "n8n-db-password"
  replication {
    auto {}
  }
  depends_on = [google_project_service.enabled_apis]
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.n8n_db_password.id
  secret_data = random_password.db_password.result
}

# n8n Encryption Key Secret
resource "random_password" "encryption_key" {
  length  = 32
  special = true
}

resource "google_secret_manager_secret" "n8n_encryption_key" {
  secret_id = "n8n-encryption-key"
  replication {
    auto {}
  }
  depends_on = [google_project_service.enabled_apis]
}

resource "google_secret_manager_secret_version" "encryption_key_version" {
  secret      = google_secret_manager_secret.n8n_encryption_key.id
  secret_data = random_password.encryption_key.result
}

# Grant Secret Access to the Service Account
resource "google_secret_manager_secret_iam_member" "db_password_access" {
  secret_id = google_secret_manager_secret.n8n_db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.n8n_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "encryption_key_access" {
  secret_id = google_secret_manager_secret.n8n_encryption_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.n8n_sa.email}"
}
```

### 2.5 Cloud Run Service

Deploy the n8n container, connecting the database and secrets.

```terraform
resource "google_cloud_run_v2_service" "n8n_service" {
  name     = "n8n"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.n8n_sa.email

    containers {
      image = "n8nio/n8n:latest"

      # Overriding default entrypoint to ensure DB proxy starts
      command = ["/bin/sh"]
      args    = ["-c", "sleep 5; n8n start"]

      ports {
        container_port = 5678
      }

      resources {
        limits = {
          memory = "2Gi"
          cpu    = "1000m"
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
        name  = "WEBHOOK_URL"
        value = "https://n8n-${var.project_id}.${var.region}.run.app" # To be replaced with domain mapping if applicable
      }
      env {
        name  = "DB_TYPE"
        value = "postgresdb"
      }
      env {
        name  = "DB_POSTGRESDB_DATABASE"
        value = google_sql_database.n8n_db.name
      }
      env {
        name  = "DB_POSTGRESDB_USER"
        value = google_sql_user.n8n_db_user.name
      }
      env {
        name  = "DB_POSTGRESDB_HOST"
        # Cloud Run connects to Cloud SQL via unix sockets when volumes are configured
        value = "/cloudsql/${google_sql_database_instance.n8n_db_instance.connection_name}"
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
```

### 2.6 Terraform Outputs

Expose key attributes for verification.

```terraform
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
```

## 3. Taskfile Automation (`Taskfile.yml`)

Use `task` to automate standard operations consistently.

```yaml
version: '3'

tasks:
  init:
    desc: Initialize Terraform
    cmds:
      - terraform init

  plan:
    desc: Plan Terraform configuration
    cmds:
      - terraform plan

  up:
    desc: Apply Terraform to provision infrastructure
    cmds:
      - terraform apply -auto-approve

  down:
    desc: Teardown Terraform infrastructure
    cmds:
      - terraform destroy -auto-approve

  clean:
    desc: Remove temporarly files and terraform state locks
    cmds:
      - rm -rf .terraform
      - rm -f .terraform.lock.hcl
      - rm -f tfplan
      - rm -rf .tmp/

  lint:
    desc: Format and lint Terraform
    cmds:
      - terraform fmt -recursive
      - tflint --recursive
```

## 4. Code Quality & Verification (`.pre-commit-config.yaml`)

Use `pre-commit` hooks to enforce security, code quality, and formatting standards before code is submitted.

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-added-large-files

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.86.0
    hooks:
      - id: terraform_fmt
      - id: terraform_tflint
      - id: terraform_validate

  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks
```

## 5. CI/CD Operations (GitHub Actions)

A GitHub Actions pipeline to validate changes. This pipeline should utilize `Taskfile.yml` to trigger the commands defined above and use Workload Identity Federation (WIF) instead of long-lived GCP keys.

### `.github/workflows/ci.yml`

```yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main
  pull_request:

jobs:
  validate-and-deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: "read"

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Install Task
        uses: arduino/setup-task@v2

      - name: Initialize
        run: task init

      - name: Lint and Validate
        run: task lint

```

## 6. Demo Workflow: Securing Vertex AI Calls via Metadata Server

The complete n8n workflow JSON template is available in [`templates/demo-vertex-ai-workflow.json.tpl`](../templates/demo-vertex-ai-workflow.json.tpl). To use this, it must be rendered by Terraform to populate the `${project_id}` and `${model_id}` variables.

Instead of hardcoding API keys, n8n can inherit the IAM privileges of the underlying Cloud Run environment by querying the GCP Metadata Server.

### Step 1: Code Node (Authentication)

Create a **Code Node** in n8n. Use the following JavaScript code to hit the metadata server. This returns a valid OAuth 2.0 Access Token on behalf of the `n8n-service-account`.

```javascript
// Query the Compute Metadata Server for an OAuth token
const options = {
    method: 'GET',
    url: 'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',
    headers: {
        'Metadata-Flavor': 'Google'
    },
    json: true
};

try {
    const response = await this.helpers.request(options);

    // Pass the token to the next node
    return {
        json: {
            access_token: response.access_token,
            expires_in: response.expires_in
        }
    };
} catch (error) {
    throw new Error(`Failed to fetch metadata token: ${error.message}`);
}
```

### Step 2: HTTP Request Node (Vertex AI)

Attach an **HTTP Request Node** to the output of the Code Node.

* **Method:** `POST`
* **URL:** `https://aiplatform.googleapis.com/v1/projects/${project_id}/locations/global/publishers/google/models/${model_id}:generateContent`
* **Authentication:** `None`
* **Headers:**
  * Name: `Authorization`
  * Value: `Bearer {{$json.access_token}}`
* **Body Type:** `JSON`
* **Body Content:**

```json
{
  "contents": [
    {
      "role": "user",
      "parts": [
        {
          "text": "Hello Gemini, from an n8n workflow on Cloud Run!"
        }
      ]
    }
  ]
}
```

### Workflow Execution Flow

1. **Code Node** triggers automatically or manually.
2. It sends a generic GET request to `http://metadata.google.internal/...` indicating it is a Google service via the `Metadata-Flavor: Google` header.
3. Because Cloud Run operates under the `n8n-service-account`, the server returns an access token scoped to its permissions.
4. The **HTTP Request Node** receives this token natively via n8n's data referencing (`{{$json.access_token}}`) and uses it in the `Authorization` header to query Vertex AI securely.
