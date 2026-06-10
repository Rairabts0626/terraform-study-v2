resource "aws_launch_template" "this" {

  name_prefix = var.template_name

  image_id = var.ami

  instance_type = var.instance_type

  vpc_security_group_ids = [
    var.sg_id
  ]

  user_data = base64encode(var.user_data)

  tag_specifications {

    resource_type = "instance"

    tags = {
      Name = var.instance_name
    }
  }
}
