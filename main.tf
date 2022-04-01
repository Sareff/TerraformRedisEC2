resource "aws_vpc" "vpc-task-1" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc-task-1"
  }
}

resource "aws_subnet" "public-a-task-1" {
  cidr_block        = "10.0.10.0/24"
  vpc_id            = aws_vpc.vpc-task-1.id
  availability_zone = "eu-central-1a"

  tags = {
    Name = "public-a-task-1"
  }
}

resource "aws_subnet" "public-b-task-1" {
  cidr_block        = "10.0.11.0/24"
  vpc_id            = aws_vpc.vpc-task-1.id
  availability_zone = "eu-central-1b"

  tags = {
    Name = "public-b-task-1"
  }
}

resource "aws_subnet" "private-a-task-1" {
  cidr_block        = "10.0.20.0/24"
  vpc_id            = aws_vpc.vpc-task-1.id
  availability_zone = "eu-central-1a"

  tags = {
    Name = "private-a-task-1"
  }
}

resource "aws_subnet" "private-b-task-1" {
  cidr_block        = "10.0.21.0/24"
  vpc_id            = aws_vpc.vpc-task-1.id
  availability_zone = "eu-central-1b"

  tags = {
    Name = "private-b-task-1"
  }
}

resource "aws_internet_gateway" "ig-task-1" {
  vpc_id = aws_vpc.vpc-task-1.id

  tags = {
    Name = "ig-task-1"
  }
}

resource "aws_eip" "eip-a-task-1" {
  vpc = true
  tags = {
    Name = "eip-a-task-1"
  }
}

resource "aws_eip" "eip-b-task-1" {
  vpc = true
  tags = {
    Name = "eip-b-task-1"
  }
}

resource "aws_nat_gateway" "nat-a-task-1" {
  subnet_id     = aws_subnet.public-a-task-1.id
  allocation_id = aws_eip.eip-a-task-1.id

  tags = {
    Name = "nat-a-task-1"
  }
}

resource "aws_nat_gateway" "nat-b-task-1" {
  subnet_id     = aws_subnet.public-b-task-1.id
  allocation_id = aws_eip.eip-b-task-1.id

  tags = {
    Name = "nat-b-task-1"
  }
}

resource "aws_route_table" "public-rt-task-1" {
  vpc_id = aws_vpc.vpc-task-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig-task-1.id
  }

  tags = {
    Name = "public-rt-task-1"
  }
}

resource "aws_route_table" "private-a-task-1" {
  vpc_id = aws_vpc.vpc-task-1.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-a-task-1.id
  }

  tags = {
    Name = "private-a-task-1"
  }
}

resource "aws_route_table" "private-b-task-1" {
  vpc_id = aws_vpc.vpc-task-1.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-b-task-1.id
  }

  tags = {
    Name = "private-b-task-1"
  }
}

resource "aws_route_table_association" "private-a-assc-task-1" {
  subnet_id      = aws_subnet.private-a-task-1.id
  route_table_id = aws_route_table.private-a-task-1.id
}

resource "aws_route_table_association" "private-b-assc-task-1" {
  subnet_id      = aws_subnet.private-b-task-1.id
  route_table_id = aws_route_table.private-b-task-1.id
}

resource "aws_route_table_association" "public-a-assc-task-1" {
  subnet_id      = aws_subnet.public-a-task-1.id
  route_table_id = aws_route_table.public-rt-task-1.id
}

resource "aws_route_table_association" "public-b-assc-task-1" {
  subnet_id      = aws_subnet.public-b-task-1.id
  route_table_id = aws_route_table.public-rt-task-1.id
}

resource "aws_security_group" "sg-app-lb-task-1" {
  name   = "security-group-app-lb-task-1"
  vpc_id = aws_vpc.vpc-task-1.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Http for web-app"
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "all"
    to_port     = 0
  }
}

resource "aws_lb" "app-lb-task-1" {
  name               = "app-lb-task-1"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg-app-lb-task-1.id]
  subnets            = [aws_subnet.public-a-task-1.id, aws_subnet.public-b-task-1.id]
}

resource "aws_lb_target_group" "app-lb-tg-task-1" {
  name        = "app-lb-tg-task-1"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc-task-1.id
}

resource "aws_lb_listener" "app-lb-ltnr-task-1" {
  load_balancer_arn = aws_lb.app-lb-task-1.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app-lb-tg-task-1.arn
  }
}

resource "aws_dynamodb_table" "dynamodb-task-1" {
  name           = "dynamo-db-task-1"
  hash_key       = "recordId"
  billing_mode   = "PROVISIONED"
  write_capacity = 1
  read_capacity  = 1

  attribute {
    name = "recordId"
    type = "S"
  }
}

resource "aws_elasticache_subnet_group" "redis-sub-group-task-1" {
  name       = "redis-sub-group-task-1"
  subnet_ids = [aws_subnet.private-a-task-1.id, aws_subnet.private-b-task-1.id]
}

resource "aws_elasticache_replication_group" "redis-rep-group-task-1" {
  replication_group_id          = "redis-rep-group-task-1"
  replication_group_description = "group for creating two nodes in group"
  node_type                     = "cache.t2.micro"
  port                          = 6379
  parameter_group_name          = "default.redis6.x.cluster.on"
  subnet_group_name             = aws_elasticache_subnet_group.redis-sub-group-task-1.name
  automatic_failover_enabled    = true
  security_group_ids            = [aws_security_group.sg-redis-task-1.id]

  cluster_mode {
    replicas_per_node_group = 1
    num_node_groups         = 1
  }
}

resource "aws_security_group" "sg-redis-task-1" {
  name   = "security-group-redis-task-1"
  vpc_id = aws_vpc.vpc-task-1.id

  ingress {
    from_port       = 6379
    protocol        = "tcp"
    to_port         = 6379
    security_groups = [aws_security_group.sg-lt-task-1.id]
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "all"
    to_port     = 0
  }
}

resource "aws_s3_bucket" "bucket-task-1" {
  bucket = "bucket-task-1-true"
}

resource "aws_s3_bucket_object" "auto-load-yaml-task-1" {
  bucket = aws_s3_bucket.bucket-task-1.bucket
  key    = "config.yaml"
  source = "app/config.yaml"
}

resource "aws_s3_bucket_object" "auto-load-53-task-1" {
  bucket = aws_s3_bucket.bucket-task-1.bucket
  key    = "web-53"
  source = "app/web-53"
}

resource "aws_security_group" "sg-lt-task-1" {
  name   = "security-group-lt-task-1"
  vpc_id = aws_vpc.vpc-task-1.id

  ingress {
    from_port       = 8080
    protocol        = "tcp"
    to_port         = 8080
    security_groups = [aws_security_group.sg-app-lb-task-1.id]
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "all"
    to_port     = 0
  }
}

resource "aws_iam_instance_profile" "s3-ec2-profile-task-1" {
  name = "s3-ec2-profile-task-1"
  role = "1" # Name of created role with IAM
}

resource "aws_launch_template" "lt-task-1" {
  name          = "lt-task-1"
  instance_type = "t2.micro"
  image_id      = "ami-02f9ea74050d6f812"

  iam_instance_profile {
    arn = aws_iam_instance_profile.s3-ec2-profile-task-1.arn
  }

  placement {
    availability_zone = "eu-central-1"
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.sg-lt-task-1.id]
  }

  user_data = filebase64("scripts/userdata.sh")
}

resource "aws_autoscaling_group" "asg-task-1" {
  name                = "asg-task-1"
  vpc_zone_identifier = [aws_subnet.private-a-task-1.id, aws_subnet.private-b-task-1.id]
  desired_capacity    = 1
  min_size            = 1
  max_size            = 4
  default_cooldown    = 120
  target_group_arns   = [aws_lb_target_group.app-lb-tg-task-1.arn]

  launch_template {
    id      = aws_launch_template.lt-task-1.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "as-policy-task-1" {
  name                      = "as-policy-task-1"
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 120

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.app-lb-task-1.arn_suffix}/${aws_lb_target_group.app-lb-tg-task-1.arn_suffix}"
    }

    target_value = 20
  }

  autoscaling_group_name = aws_autoscaling_group.asg-task-1.name
}
