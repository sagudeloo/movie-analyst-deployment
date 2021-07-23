
variable "name" {
  type        = string
  description = "Name used to create de resources created."
}

variable "image_id" {
  type        = string
  description = "The AMI from which launch the instance."
}

variable "instance_type" {
  type        = string
  description = "Type of instance to launch."
}

variable "security_groups" {
  type        = list(string)
  description = "List of security groups to assosiate."
}

variable "min_size" {
  type        = number
  description = "Min number of instances deployed."
}

variable "max_size" {
  type        = number
  description = "Max number of instances deployed."
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of instances deployed."
}

variable "vpc_zone_identifier" {
  type        = list(string)
  description = "List of subnet IDs to launch resources in."
}

variable "target_group_arns" {
  type        = list(string)
  description = "List of aws_lb_target_group ARNs to attach."
}

variable "tags" {
  type        = map(string)
  description = "Tags for attach to Autoscaling group and propagate at launch resources."
}

variable "template" {
  type        = string
  description = "Template file path"
}

variable "template_vars" {
  type        = any
  default     = {}
  description = "Variables that will rendered in template"
}
