# AGENTS.md - Google Cloud n8n Workflows

Welcome to the **GCP n8n Workflows** project. This document provides technical context and operational guidelines for AI agents working on this codebase.

## Project Overview

This project automates the deployment of **n8n** on **Google Cloud Run** using Terraform. It features a hardened architecture with Cloud SQL (PostgreSQL), Secret Manager, and native Vertex AI integration.

### Key Technologies

- **Infrastructure**: Terraform (GCP Provider)
- **Automation Platform**: n8n (running on Cloud Run)
- **Database**: Cloud SQL for PostgreSQL
- **Security**: Secret Manager for sensitive keys
- **AI**: Google Vertex AI (Gemini 1.5 Flash/Pro)

## Architecture Overview

Refer to `docs/solution-design.md` for the ASCII architecture diagram and detailed component breakdown.

### Key Design Decisions

1. **Keyless Authentication**: The default demo workflow uses the GCP Metadata Server to fetch OAuth tokens for Vertex AI. This avoids storing service account keys within n8n.
2. **Infrastructure as Code**: Everything is managed via Terraform, including n8n workflow templates.
3. **Internal Networking**: Database connections use Cloud SQL Auth Proxy via unix sockets.

## Automation & Tasks

Use the `Taskfile.yml` for all common operations:

- `task lint`: Runs Terraform fmt, TFLint, and all `pre-commit` hooks.
- `task up`: Deploys/Updates infrastructure (`terraform apply`).
- `task ui`: Opens the deployed n8n instance.
- `task logs`: Streams Cloud Run logs.

## Special Instructions for AI Agents

### 1. Terraform Templates

The workflow templates in `templates/*.json.tpl` use Terraform's `templatefile` function.

- **CRITICAL**: To use JavaScript template literals (e.g., `${text}`) inside these files, you **must** escape the dollar sign with an extra `$` (e.g., `$${text}`) to prevent Terraform from attempting to interpolate them.

### 2. Workflow Expressions

In n8n `HTTP Request` nodes, if you need to use expressions in the JSON body (like `{{ $json.prompt }}`), prefix the entire body with an `=` (e.g., `={"contents": ...}`).

### 3. Secret Management

Never hardcode secrets. Always add them to `secrets.tf` and reference them in `cloudrun.tf` via `value_source`.

## Development Workflow

1. **Explore**: Read `cloudrun.tf`, `variables.tf`, and `docs/solution-design.md`.
2. **Plan**: Create/update an implementation plan in `.plans/` or the artifacts directory.
3. **Verify**: Always run `task lint` before proposing a commit.
4. **Deploy**: Use `task up` to verify template rendering and infrastructure changes.
