variable "asg_name" {
  type = string
}

variable "launch_template_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "target_group_arn" {
  type = string
}
