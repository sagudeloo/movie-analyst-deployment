terraform {

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.42"
    }

    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.10.1"
    }
  }

  required_version = ">= 1.0.1"
}

provider "aws" {
  profile = "default"
  region = "us-west-1"
}

provider "digitalocean" {
  token = var.DO_PAT
}

locals {
  common_tags = {
    project = var.project
    responsible = var.responsible
  }
}

# AMI

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Security groups

resource "aws_security_group" "web_service_sg" {
  name = "web_service_sg"
  vpc_id = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    {
      Name = "web_service_sg"
    },
    local.common_tags
  )
}

resource "aws_security_group_rule" "web_service_sg_rule" {
  security_group_id = aws_security_group.web_service_sg.id
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  source_security_group_id = aws_security_group.movie_analyst_lb_sg.id
}

resource "aws_security_group" "movie_analyst_lb_sg" {
  name = "movie_analyst_lb_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    {
      Name = "movie_analyst_lb_sg"
    },
    local.common_tags
  )
}

resource "aws_security_group_rule" "movie_analyst_lb_sg_rule" {
  security_group_id = aws_security_group.movie_analyst_lb_sg.id
  type = "ingress"
  from_port = 8080
  to_port = 8080
  protocol = "tcp"
  # source_security_group_id = aws_security_group.web_service_sg.id
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

# Load balancer

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "6.3.0"

  name = "movie-analyst-lb"
  internal = false
  load_balancer_type = "application"
  vpc_id = var.vpc_id
  subnets = var.public_subnets_id
  security_groups = [aws_security_group.movie_analyst_lb_sg.id]

  target_groups = [
    {
      name = "movie-analyst-ui-tg"
      backend_port = 80
      backend_protocol  = "HTTP"
    },
    {
      name = "movie-analyst-api-tg"
      backend_port = 80
      backend_protocol  = "HTTP"
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = var.domain_certificate
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    },
    {
      port               = 8080
      protocol           = "HTTP"
      target_group_index = 1
    }
  ]

  tags = merge(
    {
      Name = "movie_analyst_front_lb"
    },
    local.common_tags
  )
  
}

# UI userd_data template

module "ui_provisioner" {
  source = "./modules/shellscript-template"

  template = "./scripts/ui-provisioner.tpl"
  vars = {
    port = 80
    project_repo = "https://github.com/sagudeloo/movie-analyst-ui.git"
    back_host = "${module.alb.lb_dns_name}:8080"
  }
  
}

# Autoscaling UI

module "ui-asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "4.4.0"
  
  name = "movie_analyst_ui_server_asg"

  image_id = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  security_groups = [ aws_security_group.web_service_sg.id ]
  user_data = module.ui_provisioner.rendered
  min_size = 1
  max_size = 2
  desired_capacity = 1
  health_check_grace_period = 300
  health_check_type = "ELB"
  vpc_zone_identifier = var.private_subnets_id
  target_group_arns = [ module.alb.target_group_arns[0] ]
  use_lc    = true
  create_lc  = true

  tags = [
    {
      key = "Name"
      value = "movie_analyst_ui_server"
      propagate_at_launch = true
    },
    {
      key = "project"
      value = var.project
      propagate_at_launch = true
    },
    {
      key = "responsible"
      value = var.responsible
      propagate_at_launch = true
    }
  ]
}

# API user_data template

module "api_provisioner" {
  source = "./modules/shellscript-template"

  template = "./scripts/api-provisioner.tpl"
  vars = {
    project_repo = "https://github.com/juan-ruiz/movie-analyst-api.git"
    port = "80"
    db_host = "192.168.10.30"
    db_name = "movie_db"
    db_user = "applicationuser"
    db_pass = "applicationpass"
  }
  
}

# Autoscaling API

module "api-asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "4.4.0"
  
  name = "movie_analyst_api_server_asg"
  propagate_name = true
  image_id = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  security_groups = [ aws_security_group.web_service_sg.id ]
  user_data = module.api_provisioner.rendered
  min_size = 1
  max_size = 2
  desired_capacity = 1
  health_check_grace_period = 300
  health_check_type = "ELB"
  vpc_zone_identifier = var.private_subnets_id
  target_group_arns = [ module.alb.target_group_arns[1] ]
  use_lc    = true
  create_lc  = true

  tags = [
    {
      key = "project"
      value = var.project
      propagate_at_launch = true
    },
    {
      key = "responsible"
      value = var.responsible
      propagate_at_launch = true
    }
  ]
}


# Domain name

resource "digitalocean_domain" "domain" {
  name = "culea.me"
}

resource "digitalocean_record" "cname_lb" {
  domain = digitalocean_domain.domain.name
  type = "CNAME"
  name = "${var.project}"
  value = "${module.alb.lb_dns_name}."
}
