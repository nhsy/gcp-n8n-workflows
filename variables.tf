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
