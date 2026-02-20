variable "project_id" {
  type        = string
  description = "The GCP Project ID"
}

variable "region" {
  type        = string
  description = "The GCP Region"
  default     = "europe-west1"
}

variable "model_id" {
  type        = string
  description = "The Vertex AI Gemini model ID"
  default     = "gemini-3-flash-preview"
}

variable "n8n_url" {
  type        = string
  description = "The URL of the n8n Cloud Run service. Populated after initial deployment to set N8N_HOST and WEBHOOK_URL."
  default     = ""
}
