# # # # # # # # # # # #
# #  Vars
# # # # # # # # # # # #

variable "environment" {
  default = "qa" 
}
variable "profile" {
  description = "AWS Profile to use"
  default     = "default"
}
variable "region" {
  default = "us-west-2"
}
variable "function_name" {
  default = "imageScanner"
}
variable "handler" {
  default = "imageScanner.lambda_handler"
}
variable "runtime" {
  default = "python2.7"
}
variable "boto3_layer_name" {}
variable "boto3_layer_version" {}
variable "encrypted_hook_url" {}
