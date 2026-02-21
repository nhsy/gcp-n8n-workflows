variable "project_id" {
  type        = string
  description = "The GCP Project ID"
}

variable "region" {
  type        = string
  description = "The GCP Region"
  default     = "europe-west1"
}

variable "vertexai_model_id" {
  type        = string
  description = "The Vertex AI Gemini model ID"
  default     = "gemini-3-flash-preview"
}

variable "vertexai_location" {
  type        = string
  description = "The Vertex AI location (e.g., global, us-central1)"
  default     = "global"
}

variable "database_tier" {
  type        = string
  description = "The Cloud SQL instance tier"
  default     = "db-f1-micro"
}

variable "cloudrun_cpu" {
  type        = string
  description = "The CPU limit for the Cloud Run service"
  default     = "1"
}

variable "cloudrun_memory" {
  type        = string
  description = "The memory limit for the Cloud Run service"
  default     = "512Mi"
}
