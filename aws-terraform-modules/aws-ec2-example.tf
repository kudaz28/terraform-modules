provider "aws" 
{
  region = "us-east-2"
  access_key = "AKIAIL3URTBNUIAP4BYQ"
  secret_key = "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"
}

resource "aws_instance" "webserver"
{
  ami                                  = "ami-0707c25547869ac64"
  instance_type                        = "t2.micro"
  instance_initiated_shutdown_behavior = "start"
}



