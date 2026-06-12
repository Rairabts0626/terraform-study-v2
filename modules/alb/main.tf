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
    path     = "/"
    protocol = "HTTP"

    matcher = "200-399"
  }

  tags = {
    Name = var.target_group_name
  }
}


resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.this.arn

  port = 80

  protocol = "HTTP"

  default_action {

    type = "redirect"

    redirect {

      port = "443"

      protocol = "HTTPS"

      status_code = "HTTP_301"
    }
  }
}


resource "aws_lb_listener" "https" {

  load_balancer_arn = aws_lb.this.arn

  port = 443

  protocol = "HTTPS"

  ssl_policy = "ELBSecurityPolicy-2016-08"

  certificate_arn = var.certificate_arn

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.this.arn
  }
}
