terraform {

  backend "s3" {

    bucket = "terraform-study-v2-state-raira"

    key = "terraform-study-v2/terraform.tfstate"

    region = "ap-northeast-1"

    dynamodb_table = "terraform-locks"
  }
}
