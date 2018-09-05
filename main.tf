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

resource "aws_s3_bucket" "custodian_output" {
  bucket = "${var.namespace}-${var.stage}-${var.region}-${var.name}-custodian-output"

  tags {
    Name      = "${var.name}-custodian-output"
    Namespace = "${var.namespace}"
    Stage     = "${var.stage}"
  }

  versioning {
    enabled = true
  }

  force_destroy = true
}

module "cloudtrail_sqs_queue" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-sqs.git?ref=master"
  name   = "${var.namespace}-${var.stage}-${var.region}-${var.name}-sqs"

  tags = {
    Namespace = "${var.namespace}"
    Stage     = "${var.stage}"
  }
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

resource "aws_iam_policy" "custodian_output_s3_policy" {
  name        = "${var.region}-${var.name}-s3-policy"
  path        = "/${var.namespace}/${var.stage}/"
  description = "Allow Custodian to Write to S3 Bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
		{
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListAllMyBuckets"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["$${aws_s3_bucket.custodian_output.arn}"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": ["$${aws_s3_bucket.custodian_output.arn}/*"]
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

resource "aws_iam_role_policy_attachment" "sqs" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

# Needs this to do Looksup
# FIXME: reduce scope
resource "aws_iam_role_policy_attachment" "iam" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}
