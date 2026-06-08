variable "alb_name" {
  type = string
}

variable "target_group_name" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "instance_a_id" {
  type = string
}

variable "instance_c_id" {
  type = string
} 

