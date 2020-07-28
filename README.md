Rough exploration of Terraform for setting up a Cloud9 AWS sub-account for interviews

Set up AWS for Cloud9-based interviews:
  - Create a new sub-account
  - Set up permissions for users in an "interviewers" group from a main account to admin cloud9
  - Set up a "candidates" group in the sub-account
  - Create a dummy "jdoe" candidate user

# Variables

- `account_email`: email address to set as the root user for the sub-account.

# Notes

- If already in an organization, use `data "aws_organization_organization"` 
  instead of `resource "aws_organization_organization"`
- The cloud9 environment itself is not included.  Could optionally have it be 
  created with the sub-account root as the owner, but that's likely more 
  trouble than helpful.  In your own env it may make sense to reference 
  existing users.
