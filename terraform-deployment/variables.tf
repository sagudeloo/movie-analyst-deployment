variable "instance_type" {
  type = string
  description = "Instance Type"
}

# variable "ami" {
#   type = string
#   description = "AMI to use in the UI and API instances"
# }

variable "vpc_id" {
  type = string
  description = "VPC id to deploy the infrastructure"
}

variable "public_subnets_id" {
  type = list(string)
  description = "Public subnet id in the vpc"
}

variable "private_subnets_id" {
 type = list(string)
 description = "Private subnet id in the vpc"
}

# variable "name" {
#   type = string
#   description = "name"
# }

variable "responsible" {
  type = string
  description = "Responsible of the deployment"
}

variable "project" {
  type = string
  description = "Project name"
}

variable "domain_certificate" {
  type = string
  description = "Certificate to load balancer domain"
}

variable "DO_PAT" {}