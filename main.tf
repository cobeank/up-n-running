resource "aws_instance" "awslab" {
  ami           = "ami-0ca5a2f40c2601df6"
  instance_type = "t2.micro"

  tags = {
    Name = "web-server1"
  }
}
