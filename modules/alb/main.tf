resource "aws_lb" "this" {

  name = var.alb_name

  internal = false

  load_balancer_type = "application"

  security_groups = [
    var.alb_sg_id
  ]

  subnets = var.subnet_ids

  tags = {
    Name = var.alb_name
  }
}

resource "aws_lb_target_group" "this" {

  name = var.target_group_name

  port = 80

  protocol = "HTTP"

  vpc_id = var.vpc_id

  health_check {

    path = "/"

    protocol = "HTTP"
  }

  tags = {
    Name = var.target_group_name
  }
}

resource "aws_lb_target_group_attachment" "web_a" {

  target_group_arn = aws_lb_target_group.this.arn

  target_id = var.instance_a_id

  port = 80
}

resource "aws_lb_target_group_attachment" "web_c" {

  target_group_arn = aws_lb_target_group.this.arn

  target_id = var.instance_c_id

  port = 80
}

resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.this.arn

  port = 80

  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.this.arn
  }
}
