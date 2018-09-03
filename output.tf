output "bucket_id" {
  description = "Name of the bucket."
  value       = "${aws_s3_bucket.main.id}"
}

output "bucket_arn" {
  description = "ARN of the bucket."
  value       = "${aws_s3_bucket.main.arn}"
}

output "role_arn" {
  description = "ARN of the role created."
  value       = "${aws_iam_role.role.name}"
}
