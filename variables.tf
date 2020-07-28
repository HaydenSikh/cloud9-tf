variable "aws_region" {
  description = "AWS region in which the resources will be created"
  type = string
  default = "us-west-1"
}

variable "account_email" {
  description = "Email address that will receive notifications about this account"
  type = string
}
