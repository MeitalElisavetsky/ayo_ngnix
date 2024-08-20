#       Network setups

#       Virtual Network setup
resource "aws_vpc" "meital_vp" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "my-vpc"
  }
}


#   Public Subnet setup
resource "aws_subnet" "meital_public_subnet" {
  vpc_id            = aws_vpc.meital_vp.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "subnet-public"
  }
}

#Private Subnet setup
resource "aws_subnet" "meital_private_subnet" {
  vpc_id            = aws_vpc.meital_vp.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "subnet-private"
  }
}

# INternet GateWay Setup
resource "aws_internet_gateway" "meital_igw" {
  vpc_id = aws_vpc.meital_vp.id

  tags = {
    Name = "internet-gate-way"
  }
}

resource "aws_route_table" "meital_public_rt" {
  vpc_id = aws_vpc.meital_vp.id

  tags = {
    Name = "public-route-table"
  }

}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.meital_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.meital_igw.id

}

resource "aws_route_table_association" "meital_public_association" {
  subnet_id      = aws_subnet.meital_public_subnet
  route_table_id = aws_route_table.meital_public_rt.id
}

# NAT GateWay setup for my private network

resource "aws_eip" "priv_eip" {
    vpc = true
  
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.meital_public_subnet.id
}

resource "aws_route_table" "meital_private_rt" {
  vpc_id = aws_vpc.meital_vp.id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.meital_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "meital_private_association" {
  subnet_id      = aws_subnet.meital_private_subnet.id
  route_table_id = aws_route_table.meital_private_rt.id
}


# Security group setup

# Public SG
resource "aws_security_group" "meital_public_sg" {
  name        = "public_sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.meital_vp.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-sg"
  }
}

#Private SG
resource "aws_security_group" "meital_private_sg" {
  name        = "private_sg"
  description = "Allow all outbound traffic"
  vpc_id      = aws_vpc.meital_vp.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]  # Allowing traffic from the public subnet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg"
  }
}


#       SSH key
resource "aws_key_pair" "meital_auth" {
    key_name = "meitalkey"
    public_key = file("~/.ssh/meital_ssh.pub")  
}

#       Instance Setup

resource "aws_instance" "meital-ubuntu" {
    instance_type = "t2.micro"
    ami = data.aws_ami.ubuntu_ami.id
    key_name = aws_key_pair.meital_auth.id
    vpc_security_group_ids = [aws_security_group.meital_private_sg.id]
    subnet_id = aws_subnet.meital_private_subnet.id
    user_data = file("userdata.tpl")


    root_block_device {
        volume_size = 10
    }

    provisioner "local-exec" {
        command = templatefile("${var.host_os}-ssh-config.tpl", {
            hostname = self.public_ip ,
            user = "ubuntu",
            identityfile = "~/.ssh/meital_ssh"
        })

        interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
      
    }

    tags = {
      Name = "Ubuntu-machine"
    }
}


# Load Balancer setup
resource "aws_lb" "meital_lb" {
  name               = "meital-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.meital_public_sg.id]
  subnets            = [aws_subnet.meital_public_subnet.id]

  tags = {
    Name = "meital-lb"
  }
}

resource "aws_lb_target_group" "meital_tg" {
  name     = "meital-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.meital_vp.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "meital-tg"
  }
}

resource "aws_lb_listener" "meital_listener" {
  load_balancer_arn = aws_lb.meital_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.meital_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "meital_tg_attachment" {
  target_group_arn = aws_lb_target_group.meital_tg.arn
  target_id        = aws_instance.meital-ubuntu-private.id
  port             = 80
}
