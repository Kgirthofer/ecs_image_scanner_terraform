resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}_basic_execution"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "log_access" {
  name        = "${var.function_name}_log_access"
  path        = "/"
  description = "Allows ${var.function_name} access to the required logging"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "ecr_access" {
  name        = "${var.function_name}_ecr_access"
  path        = "/"
  description = "Allows ${var.function_name} access to the required ecs and ecr items"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ecr:DescribeImageScanFindings"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "kms_access" {
  name        = "${var.function_name}_kms_decrypt_access"
  path        = "/"
  description = "Allows ${var.function_name} access to decrypt the KMS key"
  
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "kms:Decrypt",
            "Resource": [
                "${aws_kms_key.slack_lambda.arn}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "kms_access" {
  name       = "kms access"
  roles      = ["${aws_iam_role.lambda_exec.name}"]
  policy_arn = "${aws_iam_policy.kms_access.arn}"
}

resource "aws_iam_policy_attachment" "log_access" {
  name       = "log access"
  roles      = ["${aws_iam_role.lambda_exec.name}"]
  policy_arn = "${aws_iam_policy.log_access.arn}"
}

resource "aws_iam_policy_attachment" "ecr_access" {
  name       = "ecr access"
  roles      = ["${aws_iam_role.lambda_exec.name}"]
  policy_arn = "${aws_iam_policy.ecr_access.arn}"
}
