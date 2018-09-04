module "cloudtrail" {
  source                        = "git::https://github.com/cloudposse/terraform-aws-cloudtrail.git?ref=master"
  namespace                     = "${var.namespace}"
  stage                         = "${var.stage}"
  name                          = "${var.name}"
  enable_log_file_validation    = "true"
  include_global_service_events = "true"
  is_multi_region_trail         = "false"
  enable_logging                = "true"
  s3_bucket_name                = "${module.cloudtrail_s3_bucket.bucket_id}"

  event_selector = [
    {
      read_write_type           = "All"
      include_management_events = true

      data_resource = [{
        type   = "AWS::Lambda::Function"
        values = ["arn:aws:lambda"]
      }]
    },
  ]
}

module "cloudtrail_s3_bucket" {
  source    = "git::https://github.com/cloudposse/terraform-aws-cloudtrail-s3-bucket.git?ref=master"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "${var.name}"
  region    = "${var.region}"
}

resource "aws_s3_bucket" "main" {
  bucket = "${var.s3_bucket_name}"

  tags {
    Name = "${var.s3_bucket_name}"
  }

  versioning {
    enabled = true
  }

  force_destroy = true
}

resource "aws_iam_role" "role" {
  name = "${var.name}-role"
  path = "/${var.namespace}/${var.stage}/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
      }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cloudtrail" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudTrailReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatchlogs" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
