# n8n on Google Cloud Run

[![Validate Pipeline](https://github.com/nhsy/gcp-n8n-workflows/actions/workflows/validate.yml/badge.svg)](https://github.com/nhsy/gcp-n8n-workflows/actions/workflows/validate.yml)

This project provides a robust, production-ready Proof of Concept (POC) for deploying [n8n](https://n8n.io/) on Google Cloud Run using Terraform. It includes automated infrastructure provisioning, secure secret management, and a demonstration workflow that leverages GCP Workload Identity to interact with Vertex AI.

## Architecture Highlights

- **Cloud Run**: Serverless container execution for n8n.
- **Cloud SQL (PostgreSQL)**: Managed database for persistent storage.
- **Secret Manager**: Secure handling of database credentials and n8n encryption keys.
- **IAM Identity**: Dedicated Service Account with minimal privileges for Cloud SQL and Vertex AI access.
- **Vertex AI Integration**: A demo workflow that authenticates via the GCP Metadata Server using a custom JavaScript Code node.

## Prerequisites

- [Google Cloud Account](https://cloud.google.com/) and a Project ID.
- [Terraform](https://www.terraform.io/) (>= 1.5.0)
- [Go Task](https://taskfile.dev/)
- [pre-commit](https://pre-commit.com/)

## Getting Started

### 1. Configure Variables

Create a `terraform.tfvars` file in the root directory:

```hcl
project_id = "your-gcp-project-id"
region     = "europe-west1"
```

### 2. Initialize and Deploy

Use the provided `Taskfile.yml` to manage the lifecycle of the infrastructure:

```bash
# Initialize Terraform and install providers
task init

# Run linting and validation
task lint

# View the execution plan
task plan

# Provision the infrastructure
task up
```

## Standard Task Interface

| Command      | Action                                                      |
| ------------ | ----------------------------------------------------------- |
| `task init`  | Initializes Terraform backend and providers.                |
| `task plan`  | Generates and shows an execution plan.                      |
| `task up`    | Applies the Terraform configuration to provision resources. |
| `task down`  | Destroys all provisioned infrastructure.                    |
| `task lint`  | Formats code and runs `tflint` across all modules.          |
| `task clean` | Removes local terraform state and temporary files.          |

## Project Structure

- `docs/solution-design.md`: Detailed architecture and implementation design.
- `templates/`: Contains the n8n workflow template (`.tpl`) which is rendered via Terraform.
- `workflows/`: Output directory for the rendered workflow JSON.
- `*.tf`: Terraform configuration files (Provider, IAM, Database, Cloud Run, etc.).
- `.github/workflows/ci.yml`: GitHub Actions pipeline for linting and validation.

## Demo Workflow

Once deployed, you can access the n8n UI at the URL provided in the Terraform outputs. Locate the rendered `workflows/demo-vertex-ai-workflow.json` and import it into n8n.

The workflow demonstrates:

1. **Authentication**: Fetching an OAuth token from `metadata.google.internal`.
2. **Vertex AI Call**: Using the token to prompt `gemini-3-flash-preview`.

## Security

This project follows security best practices:

- **No Hardcoded Secrets**: Uses Secret Manager and random password generation.
- **Least Privilege**: The Service Account is restricted to necessary GCP APIs.
- **Linting**: Pre-commit hooks include `gitleaks` to prevent secret accidental commits.
