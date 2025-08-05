resource "aws_vpc" "aws_lab_vpc" {
  cidr_block = "10.123.0.0/16"

  tags = {
    Name = "aws-lab-vpc"
  }
}

resource "aws_subnet" "aws_lab_subnet" {
  vpc_id            = aws_vpc.aws_lab_vpc.id
  cidr_block        = "10.123.45.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "aws-lab-subnet1"
  }
}
data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "awslab" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.aws_lab_subnet.id

  tags = {
    Name = "tf-example"
  }
}
