output "kms_id" {
  value = "${aws_kms_key.slack_lambda.key_id}"
}
output "kms_arn" {
  value = "${aws_kms_key.slack_lambda.arn}"
}
