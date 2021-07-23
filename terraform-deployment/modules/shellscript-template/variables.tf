variable "template" {
  type = string
  description = "Template file path"
}

variable "vars" {
  type = any
  default = {}
  description = "Variables that will rendered in template"
}
