# Create a VPC
resource "aws_vpc" "autoscale_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create the first Subnet
resource "aws_subnet" "autoscale_subnet_az1" {
  vpc_id            = aws_vpc.autoscale_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}

# Create the second Subnet
resource "aws_subnet" "autoscale_subnet_az2" {
  vpc_id            = aws_vpc.autoscale_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "autoscale_igw" {
  vpc_id = aws_vpc.autoscale_vpc.id
}

# Create a Route Table
resource "aws_route_table" "autoscale_route_table" {
  vpc_id = aws_vpc.autoscale_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.autoscale_igw.id
  }
}

# Associate the Route Table with the Subnets
resource "aws_route_table_association" "autoscale_rta_az1" {
  subnet_id      = aws_subnet.autoscale_subnet_az1.id
  route_table_id = aws_route_table.autoscale_route_table.id
}

resource "aws_route_table_association" "autoscale_rta_az2" {
  subnet_id      = aws_subnet.autoscale_subnet_az2.id
  route_table_id = aws_route_table.autoscale_route_table.id
}

# Create a Security Group
resource "aws_security_group" "autoscale_sg" {
  vpc_id = aws_vpc.autoscale_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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

# Create an EC2 Instance
resource "aws_instance" "autoscale_instance" {
  ami                    = "ami-0e86e20dae9224db8"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.autoscale_subnet_az1.id
  vpc_security_group_ids = [aws_security_group.autoscale_sg.id]

  tags = {
    Name = "autoscale-ec2"
  }
}

# Create a Launch Template
resource "aws_launch_template" "autoscale_launch_template" {
  name_prefix   = "autoscale-template-"
  image_id      = aws_instance.autoscale_instance.ami
  instance_type = aws_instance.autoscale_instance.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.autoscale_sg.id]
    subnet_id                   = aws_subnet.autoscale_subnet_az1.id
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "autoscale-instance"
    }
  }
}

# Create an Auto Scaling Group
resource "aws_autoscaling_group" "autoscale_asg" {
  launch_template {
    id      = aws_launch_template.autoscale_launch_template.id
    version = "$Latest"
  }

  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  vpc_zone_identifier  = [aws_subnet.autoscale_subnet_az1.id, aws_subnet.autoscale_subnet_az2.id]
  target_group_arns    = [aws_lb_target_group.autoscale_target_group.arn]

  tag {
    key                 = "Name"
    value               = "autoscale-instance"
    propagate_at_launch = true
  }
}

# Create a Load Balancer
resource "aws_lb" "autoscale_lb" {
  name               = "autoscale-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.autoscale_sg.id]
  subnets            = [aws_subnet.autoscale_subnet_az1.id, aws_subnet.autoscale_subnet_az2.id]
  enable_deletion_protection = false
}

# Create a Target Group
resource "aws_lb_target_group" "autoscale_target_group" {
  name     = "autoscale-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.autoscale_vpc.id
}

# Create a Listener for the Load Balancer
resource "aws_lb_listener" "autoscale_listener" {
  load_balancer_arn = aws_lb.autoscale_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.autoscale_target_group.arn
  }
}

