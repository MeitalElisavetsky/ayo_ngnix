data "aws_ami" "ubuntu_ami" {
    most_recent = true
    owners = [""]

    filter {
      name = "ubuntu"
      values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    }
}