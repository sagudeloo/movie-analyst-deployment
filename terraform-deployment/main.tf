terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.42"
    }
  }

  required_version = ">= 1.0.1"
}

provider "aws" {
  profile = "default"
  region = "us-west-1"
}

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

  tags = {
    Name = "web_service_sg"
    project = var.project
    responsible = var.responsible
  }
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
    from_port = 8080
    to_port = 8080
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

  tags = {
    Name = "movie_analyst_lb_sg"
    project = var.project
    responsible = var.responsible
  }
}

resource "aws_lb" "movie_analyst_lb" {
  name = "movie-analyst-front-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.movie_analyst_lb_sg.id]
  subnets = var.public_subnets_id

  tags = {
    Name = "movie_analyst_front_lb"
    project = var.project
    responsible = var.responsible
  }
}

resource "aws_lb_listener" "movie_analyst_ui_lb_ls" {
  load_balancer_arn = aws_lb.movie_analyst_lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.movie_analyst_ui.arn
  }

  tags = {
    Name = "movie_analyst_ui_lb_ls"
    project = var.project
    responsible = var.responsible
  }
}

resource "aws_lb_listener" "movie_analyst_api_lb_ls" {
  load_balancer_arn = aws_lb.movie_analyst_lb.arn
  port = 8080
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.movie_analyst_api.arn
  }

  tags = {
    Name = "movie_analyst_api_lb_ls"
    project = var.project
    responsible = var.responsible
  }
}

resource "aws_lb_target_group" "movie_analyst_ui" {
  name = "movie-analyst-ui-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id

  tags = {
    Name = "movie_analyst_ui_tg"
    project = var.project
    responsible = var.responsible
  }
}

resource "aws_lb_target_group_attachment" "movie_analyst_ui" {
  target_group_arn = aws_lb_target_group.movie_analyst_ui.arn
  target_id = aws_instance.movie_analyst_ui_server.id
  port = 80
}

resource "aws_lb_target_group" "movie_analyst_api" {
  name = "movie-analyst-api-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id

  tags = {
    Name = "movie_analyst_api_tg"
    project = var.project
    responsible = var.responsible
  }
}

resource "aws_lb_target_group_attachment" "movie_analyst_api" {
  target_group_arn = aws_lb_target_group.movie_analyst_api.arn
  target_id = aws_instance.movie_analyst_api_server.id
  port = 80
}

data "template_file" "ui_provisioner" {

  template = file("./scripts/ui-provisioner.tpl")
  vars = {
    project_repo = "https://github.com/sagudeloo/movie-analyst-ui.git"
    port = "80"
    back_host = "${aws_lb.movie_analyst_lb.dns_name}:8080"
  }
  
}

data "template_cloudinit_config" "movie_analyst_ui_server_config" {

  gzip = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content = data.template_file.ui_provisioner.rendered
  }
}

resource "aws_instance" "movie_analyst_ui_server" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id = element(var.public_subnets_id, 0)
  vpc_security_group_ids = [aws_security_group.web_service_sg.id]
  user_data = data.template_cloudinit_config.movie_analyst_ui_server_config.rendered
  
  tags = {
    Name = "movie_analyst_ui_server"
    project = var.project
    responsible = var.responsible
  }
  
  volume_tags = {
    Name = "movie_analyst_ui_server"
    project = var.project
    responsible = var.responsible
  }
  
}

data "template_file" "api_provisioner" {

  template = file("./scripts/api-provisioner.tpl")
  
  vars = {
    project_repo = "https://github.com/juan-ruiz/movie-analyst-api.git"
    port = "80"
    db_host = "192.168.10.30"
    db_name = "movie_db"
    db_user = "applicationuser"
    db_pass = "applicationpass"
  }
}

data "template_cloudinit_config" "movie_analyst_api_server_config" {

  gzip = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content = data.template_file.api_provisioner.rendered
  }
}

resource "aws_instance" "movie_analyst_api_server" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id = element(var.public_subnets_id, 0)
  vpc_security_group_ids = [aws_security_group.web_service_sg.id]
  user_data = data.template_cloudinit_config.movie_analyst_api_server_config.rendered

  tags = {
    Name = "movie_analyst_api_server"
    project = var.project
    responsible = var.responsible
  }

  volume_tags = {
    Name = "movie_analyst_api_server"
    project = var.project
    responsible = var.responsible
  }

}