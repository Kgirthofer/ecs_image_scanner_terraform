resource "aws_cloudwatch_event_rule" "putImage" {
  name        = "capture-ecr-put-image"
  description = "Capture Each ECR Put Image Operation"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ecr"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "ecr.amazonaws.com"
    ],
    "eventName": [
      "PutImage"
    ]
  }
}
PATTERN
}
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = "${aws_cloudwatch_event_rule.putImage.name}"
  target_id = "ecrPutImage"
  arn       = "${aws_lambda_function.imageScanner.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.imageScanner.arn}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.putImage.arn}"
}
