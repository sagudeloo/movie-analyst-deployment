
packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ui" {
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
  vpc_id        = "vpc-0d2831659ef89870c"
  subnet_id     = "subnet-0088df5de3a4fe490"
  region        = "us-west-1"
  instance_type = "t2.micro"
  ssh_username  = "ubuntu"
  ami_name      = "movie_analyst_api_{{timestamp}}"

  run_tags = {
    project     = "ramp-up-devops"
    responsible = "stiven.agudeloo"
  }

  run_volume_tags = {
    project     = "ramp-up-devops"
    responsible = "stiven.agudeloo"
  }
}

build {
  sources = [
    "source.amazon-ebs.ui"
  ]

  provisioner "ansible" {
    playbook_file = "../ansible-provision/api.yml"
    galaxy_file   = "../ansible-provision/requirements.yml"
  }
}