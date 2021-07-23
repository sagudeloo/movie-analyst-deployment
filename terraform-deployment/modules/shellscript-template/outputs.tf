output "rendered" {
  description = "Rendered shellscript template"
  value = data.template_cloudinit_config.this.rendered
}