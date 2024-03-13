resource "aws_vpc" "demo" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
}

resource "aws_subnet" "sub1a" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub1b" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.demo.id
}

resource "aws_route_table" "rt" {
  vpc_id = "aws_vpc.demo.id"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rt1" {
  subnet_id      = aws_subnet.sub1a.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rt2" {
  subnet_id      = aws_subnet.sub1b.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "vpcsg" {
  name   = "vpc"
  vpc_id = aws_vpc.demo.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "task1" {
  ami           = "ami-03bb6d83c60fc5f7c"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.vpcsg.id]
  subnet_id = aws_subnet.sub1a.id
}

resource "aws_instance" "task2" {
  ami           = "ami-03bb6d83c60fc5f7c"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.vpcsg.id]
  subnet_id = aws_subnet.sub1b.id
}

resource "aws_s3_bucket" "s3" {
  bucket = "vinay-1827-s3bucket"
}

resource "aws_lb" "alb" {
  name               = "task-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.vpcsg.id]
  subnets            = [aws_subnet.sub1a.id,aws_subnet.sub1b.id]
}
resource "aws_lb_target_group" "alb-tg" {
  name        = "alb-tg"
  target_type = "alb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.demo.id
}

resource "aws_lb_target_group_attachment" "tg1" {
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id        = aws_instance.task1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg2" {
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id        = aws_instance.task2.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.alb-tg.arn
    type             = "forward"
  }
}

output "loadbalancerdns" {
  value = aws_lb.alb.dns_name
}
