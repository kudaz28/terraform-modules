provider "aws" {
  profile     = "dev"
  region      = "eu-west-1"
}

resource "aws_instance" "main" {

  ami                                  = "ami-0707c25547869ac64"
  instance_type                        = "t2.medium"
  availability_zone                    = "eu-west-1a"
  subnet_id                            = "subnet-02e75e9ee252a917c"
  key_name                             = "djc"
  vpc_security_group_ids               = ["sg-003de51ac042945c0"]
  instance_initiated_shutdown_behavior = "stop"
  iam_instance_profile                 = "ecloud-elasticbeanstalk-ec2-role-motor-enrichment-data-devx"
  user_data                            = "${data.template_file.userdata.rendered}"


  tags {
    Name = "cue-integration-docker-machine"
    cost_center            = "c148"
    environment_type       = "upstart installation"
    environment_owner      = "brett-jones"
    project_code           = "NR140"
    project_name           = "Underwriting Data CUE"
    terraform              = "true"
  }
}

data "template_file" "userdata" {
  template = "${file("userdata.tpl")}"
}

