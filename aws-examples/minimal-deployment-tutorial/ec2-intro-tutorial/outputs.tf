output "ami-id" {
  description = "ID of the Amazon Machine Image used for our EC2 instance"
  value       = "${data.aws_ami.amazon-linux.id}"
}

output "name" {
  description = "Amazon Resource Name of our EC2 instance"
  value       = "${aws_instance.test-ec2.arn}"
}
