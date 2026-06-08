##追記　VPC
terraform {

  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {

  region = "ap-northeast-1"
}

module "vpc" {

  source = "./modules/vpc"

  vpc_cidr = "10.0.0.0/16"

  vpc_name = "terraform-study-v3-vpc"
}

##追記　パブリックサブネット
resource "aws_subnet" "public_a" {

  vpc_id = module.vpc.vpc_id

  cidr_block = "10.0.1.0/24"

  availability_zone = "ap-northeast-1a"

  map_public_ip_on_launch = true

  tags = {
    Name = "public-a"
  }
}

resource "aws_subnet" "public_c" {

  vpc_id = module.vpc.vpc_id

  cidr_block = "10.0.2.0/24"

  availability_zone = "ap-northeast-1c"

  map_public_ip_on_launch = true

  tags = {
    Name = "public-c"
  }
}

##追記 IGW
resource "aws_internet_gateway" "main" {

  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "terraform-study-v2-igw"
  }
}

##追記　ルートテーブル
resource "aws_route_table" "public" {

  vpc_id = module.vpc.vpc_id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "terraform-study-v2-public-rt"
  }
}

##ルートテーブルへ紐づけ
resource "aws_route_table_association" "public_a" {

  subnet_id = aws_subnet.public_a.id

  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {

  subnet_id = aws_subnet.public_c.id

  route_table_id = aws_route_table.public.id
}


##追記　セキュリティグループ
resource "aws_security_group" "web" {

  name = "terraform-study-v2-sg"

  description = "Security Group for EC2"

  vpc_id = module.vpc.vpc_id

  ingress {

    description = "SSH"

    from_port = 22

    to_port = 22

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    description = "HTTP"

    from_port = 80

    to_port = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-study-v2-sg"
  }
}

##ALB用　セキュリティグループ
resource "aws_security_group" "alb" {

  name = "terraform-study-v2-alb-sg"

  description = "ALB Security Group"

  vpc_id = module.vpc.vpc_id

  ingress {

    from_port = 80

    to_port = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-study-v2-alb-sg"
  }
}


##AMI
data "aws_ami" "amazon_linux" {

  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}

##追記　EC2作成
resource "aws_instance" "web_a" {

  ami = data.aws_ami.amazon_linux.id

  instance_type = "t3.micro"

  subnet_id = aws_subnet.public_a.id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]


  user_data_replace_on_change = true

  user_data = <<-EOF
#!/bin/bash

dnf update -y

dnf install nginx -y

systemctl enable nginx

systemctl start nginx

echo "<h1>Server A</h1>" > /usr/share/nginx/html/index.html

EOF

  tags = {
    Name = "terraform-study-v2-ec2-a"
  }
}

#ターゲットグループ紐づけ
resource "aws_lb_target_group_attachment" "web_a" {

  target_group_arn = aws_lb_target_group.main.arn

  target_id = aws_instance.web_a.id

  port = 80
}


resource "aws_instance" "web_c" {

  ami = data.aws_ami.amazon_linux.id

  instance_type = "t3.micro"

  subnet_id = aws_subnet.public_c.id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  user_data_replace_on_change = true

  user_data = <<-EOF
#!/bin/bash

dnf update -y

dnf install nginx -y

systemctl enable nginx

systemctl start nginx

echo "<h1>Server C</h1>" > /usr/share/nginx/html/index.html

EOF

  tags = {
    Name = "terraform-study-v2-ec2-c"
  }
}

#ターゲットグループ紐づけ
resource "aws_lb_target_group_attachment" "web_c" {

  target_group_arn = aws_lb_target_group.main.arn

  target_id = aws_instance.web_c.id

  port = 80
}

##ALB本体
resource "aws_lb" "main" {

  name = "terraform-study-v2-alb"

  internal = false

  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_c.id
  ]

  tags = {
    Name = "terraform-study-v2-alb"
  }
}

##追記　ターゲットグループ
resource "aws_lb_target_group" "main" {

  name = "terraform-study-v2-tg"

  port = 80

  protocol = "HTTP"

  vpc_id = module.vpc.vpc_id

  health_check {

    enabled = true

    path = "/"

    protocol = "HTTP"

    matcher = "200"
  }

  tags = {
    Name = "terraform-study-v2-tg"
  }
}

##追記　ALBリスナー
resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.main.arn

  port = 80

  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.main.arn
  }
}


