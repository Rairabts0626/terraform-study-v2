resource "aws_autoscaling_group" "this" {

  name = var.asg_name

  desired_capacity = 2

  min_size = 2

  max_size = 4

  vpc_zone_identifier = var.subnet_ids

  target_group_arns = [
    var.target_group_arn
  ]

  launch_template {

    id = var.launch_template_id

    version = "$Latest"
  }

  health_check_type = "ELB"
}
