resource "aws_lambda_function" "imageScanner" {
  function_name    = "${var.function_name}"
  filename         = "lambda_function_payload.zip"
  source_code_hash = "${filebase64sha256("lambda_function_payload.zip")}"
  layers           = ["arn:aws:lambda:${var.region}:layer:${var.boto3_layer_name}:${var.boto3_layer_version}"]
  handler          = "${var.handler}"
  runtime          = "${var.runtime}"
  timeout          = "900"
  memory_size      = "1024"
  role             = "${aws_iam_role.lambda_exec.arn}"
  kms_key_arn      = "${aws_kms_key.slack_lambda.arn}"

  environment {
    variables = {
      env                 = "${var.environment}"
      kmsEncryptedHookUrl = "${var.encrypted_hook_url}"
      slackChannel        = "image-scan-results"
    }
  }
}
