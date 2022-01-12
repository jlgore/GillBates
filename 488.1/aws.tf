terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.71.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
    profile = "default"
}

module "vpc" {
    cidr = "10.0.0.0/16"
    source = "terraform-aws-modules/vpc/aws"
    name = "SEC488"
    azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
    enable_nat_gateway = true
    
    tags = {
        Terraform = "true"
        Environment = "SEC488"
    }
}

resource "aws_security_group" "ubuntu488" {
    name = "tf-sg-ubuntu488"
    description = "tf-sg-ubuntu488"
    vpc_id = "${module.vpc.vpc_id}"

    ingress {
        description = "ssh open to world"
        from_port = 1-65535
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "web open to world"
        from_port = 1-65535
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "icmp echo open to world"
        from_port = 8
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_volume_attachment" "ebs_att" {
    device_name = "/dev/xvdf"
    volume_id = "${aws_ebs_volume.ebs_vol.id}"
    instance_id = "${aws_instance.ubuntu-server.id}"
}

resource "aws_instance" "ubuntu-server" {
    ami = "ami-022c64ae7f1edeb01"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.ubuntu488.id}"]
    subnet_id = "${module.vpc.public_subnets[0]}"

    user_data = <<EOF
    #!/bin/bash
    sudo apt update > packages.txt

    EOF

    tags = {
        Name = "SEC488-MGMT"
        Class = "SEC488"
    }

}

resource "aws_ebs_volume" "ebs_vol" {
    availability_zone = "${aws_instance.ubuntu-server.availability_zone}"
    size = 8
    tags = {
        Name = "SEC488-EBS"
        Class = "SEC488"
    }
}