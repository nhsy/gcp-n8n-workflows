locals {
  n8n_host = var.n8n_url != "" ? trimprefix(var.n8n_url, "https://") : ""
}
