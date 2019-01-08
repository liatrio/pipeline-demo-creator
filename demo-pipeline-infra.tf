terraform {
  backend "s3" {
    bucket               = "pipeline-state.liatr.io"
    region               = "us-east-1"
    key                  = "pipeline-devenv.tfstate"
    workspace_key_prefix = "demo"
    dynamodb_table       = "pipeline-state-lock"
    encrypt              = "true"
  }
}

provider "aws" {
  region  = "us-east-1"
  version = "~> 1.54"
}

variable "key_file" {
  description = "key for terraform remote provisioners supplied by jenkins"
}

variable "app_name" {
  description = "Name given to this application instance"
}

variable "jenkins_user" {
  description = "User who kicked off the Jenkins job"
}

variable "ami_id" {
  default     = "ami-0080e4c5bc078760e"
  description = "AMI used for amazon linux"
}

resource "aws_instance" "dev-deployment-host" {
  instance_type   = "t2.micro"
  key_name        = "jenkins.liatr.io"
  ami             = "${var.ami_id}"
  security_groups = ["http", "https", "ssh", "egress_all"]

  tags = {
    Name         = "Pipeline ${var.app_name} dev host"
    Environment  = "demo"
    Client       = "liatrio"
    Project      = "Demo Pipeline"
    Owner        = "${var.jenkins_user}"
    DemoPipeline = "${var.app_name}"
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
      "curl https://s3-us-west-2.amazonaws.com/liatrio-authorized-keys-groups/chico_wave_3 >> ~/.ssh/authorized_keys",
      "curl https://s3-us-west-2.amazonaws.com/liatrio-authorized-keys-groups/jenkins.pub >> ~/.ssh/authorized_keys",
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
