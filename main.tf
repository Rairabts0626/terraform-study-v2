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
module "public_subnet_a" {

  source = "./modules/subnet"

  vpc_id = module.vpc.vpc_id

  subnet_cidr = "10.0.1.0/24"

  az = "ap-northeast-1a"

  subnet_name = "public-a"
}

module "public_subnet_c" {

  source = "./modules/subnet"

  vpc_id = module.vpc.vpc_id

  subnet_cidr = "10.0.2.0/24"

  az = "ap-northeast-1c"

  subnet_name = "public-c"
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

  subnet_id = module.public_subnet_a.subnet_id

  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {

  subnet_id = module.public_subnet_c.subnet_id

  route_table_id = aws_route_table.public.id
}


##追記　セキュリティグループ
module "web_security_group" {

  source = "./modules/security_group"

  vpc_id = module.vpc.vpc_id

  sg_name = "terraform-study-v2-sg"

  description = "Security Group for EC2"

  ingress_ports = [22, 80]

}



##ALB用　セキュリティグループ
module "alb_security_group" {

  source = "./modules/security_group"

  vpc_id = module.vpc.vpc_id

  sg_name = "terraform-study-v2-alb-sg"

  description = "ALB Security Group"

  ingress_ports = [80]
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
module "web_a" {

  source = "./modules/ec2"

  ami = data.aws_ami.amazon_linux.id

  instance_type = "t3.micro"

  subnet_id = module.public_subnet_a.subnet_id

  sg_id = module.web_security_group.sg_id

  instance_name = "terraform-study-v2-ec2-a"

  user_data = <<-EOF
#!/bin/bash
dnf update -y
dnf install nginx -y
systemctl enable nginx
systemctl start nginx
echo "<h1>Server A</h1>" > /usr/share/nginx/html/index.html
EOF
}



#ターゲットグループ紐づけ


module "web_c" {

  source = "./modules/ec2"

  ami = data.aws_ami.amazon_linux.id

  instance_type = "t3.micro"

  subnet_id = module.public_subnet_c.subnet_id

  sg_id = module.web_security_group.sg_id

  instance_name = "terraform-study-v2-ec2-c"

  user_data = <<-EOF
#!/bin/bash
dnf update -y
dnf install nginx -y
systemctl enable nginx
systemctl start nginx
echo "<h1>Server C</h1>" > /usr/share/nginx/html/index.html
EOF
}

#ターゲットグループ紐づけ


##ALB本体
module "alb" {

  source = "./modules/alb"

  alb_name = "terraform-study-v2-alb"

  target_group_name = "terraform-study-v2-tg"

  vpc_id = module.vpc.vpc_id

  alb_sg_id = module.alb_security_group.sg_id

  subnet_ids = [
    module.public_subnet_a.subnet_id,
    module.public_subnet_c.subnet_id
  ]

  instance_a_id = module.web_a.instance_id

  instance_c_id = module.web_c.instance_id
}

##追記　ターゲットグループ

##追記　ALBリスナー

#output "sg_id" {
#  value = aws_security_group.this.id
#}
