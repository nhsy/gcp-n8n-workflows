resource "local_file" "n8n_demo_workflow" {
  content = templatefile("${path.module}/templates/demo-vertex-ai-workflow.json.tpl", {
    project_id        = var.project_id
    vertexai_model_id = var.vertexai_model_id
    vertexai_location = var.vertexai_location
  })
  filename = "${path.module}/workflows/demo-vertex-ai-workflow.json"
}
