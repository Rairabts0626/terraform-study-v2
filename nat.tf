resource "aws_eip" "nat" {

  count = var.nat_enabled ? 1 : 0

  domain = "vpc"

  tags = {
    Name = "terraform-study-v2-nat-eip"
  }
}


resource "aws_nat_gateway" "main" {

  count = var.nat_enabled ? 1 : 0

  allocation_id = aws_eip.nat[0].id

  subnet_id = module.public_subnet_a.subnet_id

  tags = {
    Name = "terraform-study-v2-nat"
  }

  depends_on = [
    aws_internet_gateway.main
  ]
}
