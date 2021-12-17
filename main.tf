
resource "aws_vpc" "Kat-JNDI-exploit-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    "Name" = "Kat-JNDI-Exploit-VPC"
  }
}

resource "aws_subnet" "Kat-Public-Subnet-1" {
  vpc_id                  = aws_vpc.Kat-JNDI-exploit-vpc.id
  cidr_block              = var.public_subnet_1_cidr
  map_public_ip_on_launch = true
  availability_zone = "us-west-2a"

  tags = {
    "Name" = "Public-Subnet-1"
  }
}


resource "aws_route_table" "kat-Public-Route-Table" {
  vpc_id = aws_vpc.Kat-JNDI-exploit-vpc.id

  tags = {
    "Name" = "Public-Route-Table"
  }
}

resource "aws_route_table_association" "Public_Subnet_1_Association" {
  route_table_id = aws_route_table.kat-Public-Route-Table.id
  subnet_id      = aws_subnet.Kat-Public-Subnet-1.id
}


resource "aws_internet_gateway" "kat-vpc_igw" {
  vpc_id = aws_vpc.Kat-JNDI-exploit-vpc.id
  tags = {
    "Name" = "VPC-IGW"
  }
}

resource "aws_route" "kat-vpc_igw_route" {
  route_table_id         = aws_route_table.kat-Public-Route-Table.id
  gateway_id             = aws_internet_gateway.kat-vpc_igw.id
  destination_cidr_block = "0.0.0.0/0"
}

data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "kat-ec2-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDrEvI51McoC0w6nu+kbGzm8bG6LNIkFiPH5X4ITtTuki6sOe5uren7/zibzK+oHUJkJY4gTJ8m3dfXZCfGQHekz9TuT+/n9f89JJVA1Hp39gEmPWLkdl9pJtGkPooHtk1cmpooZIFYyb264HW9XTeIqpI/jYlzVTC3VTLXLFOnxajDXcIZVAt8lZJMnxDKWc+asJRFlnn4nYRZXnGSg4sdcUeWjT+atR77bb3QGUjNzUqv+bReGQI7OA8s89qHHKieLX7hHD+LpjR+lMhghCS8lsz7zGilEiPpFMtVQcZqNtZAc5UYSuglqDCZJW8tEaZH265LGwWA6QE/wZL5of1JDNChloYDq+7idcIR2DLGSG/M1rsRK1DNmraOrFaHP2rQZ5mkNeO52kcFSvVmYksECJ2lPVVXizkOGIYtIH2ipX32nMpCGuQQT7FM10AlpW/RaVLoAQkHmgDHZOIFemnLyPb6EqpZkiVgEyFdt6Wm+tKMrudhCayCs9/oU+Fb+RE= kat-my-key"

}

resource "aws_security_group" "ec2-connect-sg" {
  name   = "EC2-SG"
  vpc_id = aws_vpc.Kat-JNDI-exploit-vpc.id

  ingress = [
  {
    cidr_blocks      = ["18.237.140.160/29"]
    description      = "SSH from EC2 Instance Connect from the Browser"
    from_port        = 22
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 22
    tags = {
      Name = "Allow EC2 Instance Connect"
      }
  },{
    cidr_blocks      = ["75.72.14.230/32"]
    description      = "Inbound from corp IP to vulnerable ap"
    from_port        = 22
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 22
    tags = {
      Name = "Allow inbound to vulnerabl app from Corp IP"
    }
    }
  ]

  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "SG-OUT"
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = -1
    self             = false
    security_groups  = []
    to_port          = 0
  }]

}

resource "aws_iam_instance_profile" "kat-JNDI-EC2-Profile" {
  name = "kat-JNDI-EC2-Profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "kat-JNDI-EC2-Role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

/*
resource "aws_instance" "kat-jndiexploit-server" {
  ami             = data.aws_ami.amazon-linux.id
  associate_public_ip_address = true
  instance_type   = var.ec2_instance_type
  key_name        = aws_key_pair.ssh_key.key_name
  subnet_id       = aws_subnet.Kat-Public-Subnet-1.id
  security_groups = [aws_security_group.ec2-connect-sg.id]
  user_data       = <<-EOF
              #!/bin/bash
              sudo yum install java-1.8.0-openjdk
              wget http://web.archive.org/web/20211210224333/https://github.com/feihong-cs/JNDIExploit/releases/download/v1.2/JNDIExploit.v1.2.zip
              unzip JNDIExploit.v1.2.zip
              MY_IP=$(hostname -I)
              java -jar JNDIExploit-1.2-SNAPSHOT.jar -i $MY_IP -p 8888
              EOF
  tags = {
    Name = "kat-jndiexploit-server"
  }  

}


output "jndi-publicip" {
  value = aws_instance.kat-jndiexploit-server.public_ip
}
*/


resource "aws_instance" "kat-JNDI-vulnerable-app" {
  ami             = data.aws_ami.amazon-linux.id
  iam_instance_profile = "kat-JNDI-EC2-Profile"
  associate_public_ip_address = true
  key_name        = aws_key_pair.ssh_key.key_name
  instance_type   = var.ec2_instance_type
  subnet_id       = aws_subnet.Kat-Public-Subnet-1.id
  security_groups = [aws_security_group.ec2-connect-sg.id]
  user_data       = <<-EOF
              #!/bin/bash
              sudo yum install docker -y
              sudo yum install java-1.8.0-openjdk -y
              sudo systemctl start docker.service
              sudo docker run --name vulnerable-app -p 8080:8080 ghcr.io/christophetd/log4shell-vulnerable-app
              wget http://web.archive.org/web/20211210224333/https://github.com/feihong-cs/JNDIExploit/releases/download/v1.2/JNDIExploit.v1.2.zip
              unzip JNDIExploit.v1.2.zip
              MY_IP=$(hostname -I | awk '{print $1}')
              java -jar JNDIExploit-1.2-SNAPSHOT.jar -i $MY_IP -p 8888
              EOF
  tags = {
    Name = "kat-JNDI-vulnerable-app"
  }
}

output "vulnerableApp-publicip" {
  value = aws_instance.kat-JNDI-vulnerable-app.public_ip
}