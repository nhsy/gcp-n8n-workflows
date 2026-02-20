resource "local_file" "n8n_demo_workflow" {
  content = templatefile("${path.module}/templates/demo-vertex-ai-workflow.json.tpl", {
    project_id = var.project_id
    model_id   = var.model_id
  })
  filename = "${path.module}/workflows/demo-vertex-ai-workflow.json"
}
