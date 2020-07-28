# Pin the version of Terraform
terraform {
 required_version = "0.12.23"
}

# --------------------------------------------------------------------------
# Configure the main AWS Provider
provider "aws" {
  alias = "main"
  version = "~> 2.52"
  region = var.aws_region
}

data "aws_caller_identity" "current_main" {
  provider = aws.main
}

resource "aws_organizations_organization" "main" {
  provider = aws.main
}

resource "aws_organizations_account" "interviews" {
  provider = aws.main

  name = "interviews"
  email = var.account_email

  parent_id = aws_organizations_organization.main.roots.0.id

  iam_user_access_to_billing = "DENY"

  role_name = "Administrator"
  # There is no AWS Organizations API for reading role_name
  lifecycle {
    ignore_changes = [role_name]
  }
}

resource "aws_iam_group" "interviewers" {
  provider = aws.main

  name = "interviewers"
}

data "aws_iam_policy_document" "assume_interview_cloud9_admin" {
  provider = aws.main

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      aws_iam_role.cloud9_admin.arn
    ]
  }
}

resource "aws_iam_policy" "assume_interview_cloud9_admin" {
  provider = aws.main

  policy = data.aws_iam_policy_document.assume_interview_cloud9_admin.json
}

resource "aws_iam_group_policy_attachment" "interview_group_may_assume_interview_cloud9_admin" {
  provider = aws.main

  group = aws_iam_group.interviewers.name
  policy_arn = aws_iam_policy.assume_interview_cloud9_admin.arn
}

# --------------------------------------------------------------------------
# Configure the "interview" AWS account
provider "aws" {
  alias = "interview"
  version = "~> 2.52"
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.interviews.id}:role/${aws_organizations_account.interviews.role_name}"
  }
}

resource "aws_iam_group" "candidates" {
  provider = aws.interview
  name = "candidates"
}

data "aws_iam_policy_document" "cloud9_admin_role" {
  provider = aws.interview

  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [data.aws_caller_identity.current_main.account_id]
      type = "AWS"
    }
  }
}

resource "aws_iam_role" "cloud9_admin" {
  provider = aws.interview

  name = "cloud9_admin"
  assume_role_policy = data.aws_iam_policy_document.cloud9_admin_role.json
}

resource "aws_iam_role_policy_attachment" "cloud9_admin_may_admin_cloud9" {
  provider = aws.interview

  policy_arn = "arn:aws:iam::aws:policy/AWSCloud9Administrator"
  role = aws_iam_role.cloud9_admin.name
}

resource "aws_iam_group_policy_attachment" "candidates_group_may_be_cloud9_user" {
  provider = aws.interview

  policy_arn = "arn:aws:iam::aws:policy/AWSCloud9User"
  group = aws_iam_group.candidates.name
}

resource "aws_iam_user" "jdoe" {
  provider = aws.interview
  name = "jdoe"

}

resource "aws_iam_group_membership" "candidates_membership" {
  provider = aws.interview

  name = "tf-candidates-membership"
  group = aws_iam_group.candidates.name
  users = [
    aws_iam_user.jdoe.name
  ]
}

