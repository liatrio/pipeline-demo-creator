terraform {
        backend "s3" {
        bucket = "liatristorage"
//        key = "liatristorage/${terraform.workspace}/${var.app_name}-terraform.tfstate"
        region = "us-west-2"
    }
}

provider "aws" {
    region = "us-west-2"
}

variable "key_file" {
  description = "key for terraform remote provisioners supplied by jenkin"
}

variable "app_name" {
    description = "Name given to this application instance"
}

variable "ami_id" {
    default = "ami-6df1e514"
    description = "AMI used for amazon linux"
}


data "terraform_remote_state" "network" {
    backend = "s3"
    config {
        bucket = "liatristorage"
        key = "liatristorage/${terraform.workspace}/${var.app_name}-terraform.tfstate"
        region = "us-west-2"
    }
}

resource "aws_instance" "dev-deployment-host" {
  instance_type           = "t2.micro"
  key_name                = "jenkins.liatr.io"
  ami                     = "${var.ami_id}"
  security_groups         = ["web", "https server"]

  tags = {
    Name = "${var.app_name}"
  }


  provisioner "remote-exec" {
    connection {
      user        = "ec2-user"
      private_key = "${file("${var.key_file}")}"
    }
    inline = [
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo service docker start",
      "sudo usermod -aG docker ec2-user",
      "curl https://s3-us-west-2.amazonaws.com/liatrio-authorized-keys-groups/admins >> ~/.ssh/authorized_keys",
      "curl https://s3-us-west-2.amazonaws.com/liatrio-authorized-keys-groups/chico_vets >> ~/.ssh/authorized_keys",
      "curl https://s3-us-west-2.amazonaws.com/liatrio-authorized-keys-groups/chico_wave_3 >> ~/.ssh/authorized_keys",
      "curl https://s3-us-west-2.amazonaws.com/liatrio-authorized-keys-groups/jenkins.pub >> ~/.ssh/authorized_keys"
    ]
  }
}

data "aws_route53_zone" "liatrio" {
  name = "liatr.io"
}

resource "aws_route53_record" "dev-deployment-dns" {
  zone_id = "${data.aws_route53_zone.liatrio.zone_id}"
  name    = "dev.${var.app_name}.liatr.io"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.dev-deployment-host.public_ip}"]
}
