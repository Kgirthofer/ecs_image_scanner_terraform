resource "aws_kms_key" "slack_lambda" {
  description             = "For encrpyting and decrypting your slack urls"
  enable_key_rotation     = true
}
