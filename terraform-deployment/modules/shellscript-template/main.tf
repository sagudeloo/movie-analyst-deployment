data "template_cloudinit_config" "this" {

  gzip = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content = templatefile(var.template, var.vars)
  }
}