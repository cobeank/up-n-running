resource "aws_instance" "awslab" {
  ami           = aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.aws_lab_subnet.id

  tags = {
    Name = "tf-example"
  }
}
