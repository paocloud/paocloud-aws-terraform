variable "aws_access_key" {}
variable "aws_secret_key" {}

provider "aws" {
  region = "ap-southeast-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  tags = {
    Name = "terraform"
  }

  ami = data.aws_ami.ubuntu.id
  availability_zone = "ap-southeast-1a"
  subnet_id = "subnet-034xxx"
  vpc_security_group_ids = [ "sg-04xxx" ]
  associate_public_ip_address = true
  ipv6_address_count = 1
  instance_type = "t3a.micro"
  key_name = "paomini"

  user_data = file("prepare-ubuntu-instance.sh")

  ebs_block_device {
    device_name = "/dev/xvda"
    volume_type = "gp2"
    volume_size = 10
  }

}

resource "aws_eip" "web_eip" {
  vpc = true
  instance = aws_instance.web.id
  tags = {
    Name = "web_eip"
  }
}
