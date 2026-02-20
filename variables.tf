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
