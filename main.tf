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

locals {

  wordpress_ami = "ami-08a61904741c13ec7"
}


module "vpc" {

  source = "./modules/vpc"

  vpc_cidr = "10.0.0.0/16"

  vpc_name = "terraform-study-v3-vpc"
}

##追記　パブリック＆プライベートサブネット
module "public_subnet_a" {

  source = "./modules/subnet"

  vpc_id = module.vpc.vpc_id

  subnet_cidr = "10.0.1.0/24"

  az = "ap-northeast-1a"

  subnet_name = "public-a"

  public_ip = true
}

module "private_app_subnet_a" {

  source = "./modules/subnet"

  vpc_id = module.vpc.vpc_id

  subnet_cidr = "10.0.10.0/24"

  az = "ap-northeast-1a"

  subnet_name = "private-app-subnet-a"

  public_ip = false
}

module "public_subnet_c" {

  source = "./modules/subnet"

  vpc_id = module.vpc.vpc_id

  subnet_cidr = "10.0.2.0/24"

  az = "ap-northeast-1c"

  subnet_name = "public-c"

  public_ip = true
}

module "private_app_subnet_c" {

  source = "./modules/subnet"

  vpc_id = module.vpc.vpc_id

  subnet_cidr = "10.0.20.0/24"

  az = "ap-northeast-1c"

  subnet_name = "private-app-subnet-c"

  public_ip = false
}

module "private_db_subnet_a" {

  source = "./modules/subnet"

  vpc_id = module.vpc.vpc_id

  subnet_cidr = "10.0.30.0/24"

  az = "ap-northeast-1a"

  subnet_name = "private-db-subnet-a"

  public_ip = false
}

module "private_db_subnet_c" {

  source = "./modules/subnet"

  vpc_id = module.vpc.vpc_id

  subnet_cidr = "10.0.40.0/24"

  az = "ap-northeast-1c"

  subnet_name = "private-db-subnet-c"

  public_ip = false
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

resource "aws_route_table" "private" {

  vpc_id = module.vpc.vpc_id

  dynamic "route" {

    for_each = var.nat_enabled ? [1] : []

    content {

      cidr_block = "0.0.0.0/0"

      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "private-route-table"
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

resource "aws_route_table_association" "private_app_a" {

  subnet_id = module.private_app_subnet_a.subnet_id

  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_app_c" {

  subnet_id = module.private_app_subnet_c.subnet_id

  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_db_a" {

  subnet_id = module.private_db_subnet_a.subnet_id

  route_table_id = aws_route_table.private.id
}


resource "aws_route_table_association" "private_db_c" {

  subnet_id = module.private_db_subnet_c.subnet_id

  route_table_id = aws_route_table.private.id
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

  ingress_ports = [80, 443]
}

##DB用　セキュリティグループ
resource "aws_security_group" "db" {

  name = "terraform-study-v2-db-sg"

  description = "RDS Security Group"

  vpc_id = module.vpc.vpc_id

  ingress {

    from_port = 3306

    to_port = 3306

    protocol = "tcp"

    security_groups = [
      module.web_security_group.sg_id
    ]
  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "terraform-study-v2-db-sg"
  }
}


##DB Subnet Group
resource "aws_db_subnet_group" "main" {

  name = "terraform-study-v2-db-subnet-group"

  subnet_ids = [

    module.private_db_subnet_a.subnet_id,

    module.private_db_subnet_c.subnet_id
  ]

  tags = {

    Name = "terraform-study-v2-db-subnet-group"
  }
}

##インスタンス
resource "aws_db_instance" "wordpress" {

  identifier = "terraform-study-v2-db"

  engine = "mysql"

  engine_version = "8.0"

  instance_class = "db.t3.micro"

  allocated_storage = 20

  storage_type = "gp3"

  db_name = "wordpress"

  username = "admin"

  password = var.db_password

  publicly_accessible = false

  multi_az = false

  skip_final_snapshot = true

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    aws_security_group.db.id
  ]

  tags = {

    Name = "terraform-study-v2-db"
  }
}

##AMI
#data "aws_ami" "amazon_linux" {
#
#  most_recent = true
#
#  owners = ["amazon"]
#
#  filter {
#    name   = "name"
#    values = ["al2023-ami-*"]
#  }
#}


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

  certificate_arn = "arn:aws:acm:ap-northeast-1:957396245427:certificate/80ae360f-2763-4345-bb9a-dbae2bf05aad"

}

##追記　ランチテンプレート
module "launch_template" {

  source = "./modules/launch_template"

  template_name = "terraform-study-v2"

  ami = local.wordpress_ami

  instance_type = "t3.micro"

  sg_id = module.web_security_group.sg_id

  instance_name = "terraform-study-v2-asg"

  user_data = ""

}

##追記　ASG
module "autoscaling" {

  source = "./modules/autoscaling"

  asg_name = "terraform-study-v2-asg"

  launch_template_id = module.launch_template.launch_template_id

  subnet_ids = [

    module.private_app_subnet_a.subnet_id,

    module.private_app_subnet_c.subnet_id
  ]

  target_group_arn = module.alb.target_group_arn
}

##追記　ASG　ポリシー
module "autoscaling_policy" {

  source = "./modules/autoscaling_policy"

  policy_name = "terraform-study-v2-cpu-policy"

  asg_name = module.autoscaling.asg_name
}

##追記　SNS
module "sns" {

  source = "./modules/sns"

  topic_name = "terraform-study-v2-alert"

  email_address = var.notification_email
}

## 追記 Cloudwatch
module "cloudwatch_alarm" {

  source = "./modules/cloudwatch_alarm"

  alarm_name = "terraform-study-v2-cpu-high"

  asg_name = module.autoscaling.asg_name

  topic_arn = module.sns.topic_arn
}



#output "sg_id" {
#  value = aws_security_group.this.id
#}
