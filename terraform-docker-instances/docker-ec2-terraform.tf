provider "aws"
{
  profile     = "dev"
  region      = "eu-west-1"
}

resource "aws_instance" "main"
{

  ami                                  = "ami-0a5e707736615003c"
  instance_type                        = "t3.xlarge"
  
  ebs_block_device 
  {
    device_name = "/dev/xvda"
    volume_size = 500
    volume_type = "standard"
    delete_on_termination = true
  }
  
  availability_zone                    = "eu-west-1a"
  subnet_id                            = "subnet-0e21b0ded67ff7f8b"
  key_name                             = "docker-mock-sites"
  vpc_security_group_ids               = ["sg-37f53e4c"]
  instance_initiated_shutdown_behavior = "stop"
  user_data                            = "${data.template_file.userdata.rendered}"

  tags
  {
    Name = "docker-instance-mock-apis"
    terraform                                      = "true"
  }
}

resource "aws_iam_role" "main"
{
   name               = "ecloud-docker-ec2-role"
   path               = "/"
   assume_role_policy = "${file("assume-role-policy.json")}"
}

resource "aws_iam_instance_profile" "main"
{
   name  = "${aws_iam_role.main.name}"
   role = "${aws_iam_role.main.name}"
}

resource "aws_iam_role_policy_attachment" "main"
{
   role       = "${aws_iam_role.main.name}"
   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

data "template_file" "userdata"
{
  template = "${file("userdata.tpl")}"
}


