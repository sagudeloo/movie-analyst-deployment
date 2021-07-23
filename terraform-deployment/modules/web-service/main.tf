module "shellscript_template" {
  source = "../shellscript-template"

  template = var.template
  vars     = var.template_vars

}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "4.4.0"

  name = var.name

  image_id                  = var.image_id
  instance_type             = var.instance_type
  security_groups           = var.security_groups
  user_data                 = module.shellscript_template.rendered
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = var.vpc_zone_identifier
  target_group_arns         = var.target_group_arns
  use_lc                    = true
  create_lc                 = true

  tags = [
    for tag_key, tag_value in var.tags :
    {
      key                 = tag_key
      value               = tag_value
      propagate_at_launch = true
    }
  ]
}