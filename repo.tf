resource "aws_ecr_repository" "example" {
  name = "${var.env}-example-with-scanning"
  image_scanning_configuration {
   scan_on_push = true
  }
}
