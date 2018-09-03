# terraform-cloud-custodian

## WARNING

This module is in heavy development and is not yet ready for production use

# Example

```
# the module itself
module "custodian" {
  source         = "/Users/Lee/github/terraform-cloud-custodian"
  s3_bucket_name = "lbriggs-cloud-custodian-output"
  name           = "custodian"
  namespace      = "lbriggs"
  stage          = "dev"
  region         = "us-west-2"
}


# additional policy attachments for your custodian functions
resource "aws_iam_role_policy_attachment" "ec2" {
  role       = "${module.custodian.role_arn}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
```
