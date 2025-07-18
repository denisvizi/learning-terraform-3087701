data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner] # Bitnami
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.environment.name
  cidr = "${var.environment.network_prefix}.0.0/16"

  azs             = ["eu-central-1a","eu-central-1b","eu-central-1c"]
  public_subnets  = ["${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = var.environment.name
  }
}

module "blog_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.0.1"

  name = "${var.environment.name}-blog"

  min_size = var.asg_min
  max_size = var.asg_max
  vpc_zone_identifier = module.blog_vpc.public_subnets

  create_traffic_source_attachment = true
  traffic_source_identifier        = module.blog_alb.target_group_arns[0]
  traffic_source_type              = "elbv2"

  launch_template = {
    name_prefix   = "blog-"
    image_id      = data.aws_ami.app_ami.id
    instance_type = var.instance_type
    
    network_interfaces = [{
      delete_on_termination       = true
      security_groups             = [module.blog_sg.security_group_id]
      associate_public_ip_address = true
    }]

    instance_market_options = {
      market_type = "spot"
      spot_options = {
        max_price = null
      }
    }

    monitoring = {
      enabled = true
    }

    tag_specifications = [{
      resource_type = "instance"
      tags = {
        Name = "${var.environment.name}-blog-instance"
      }
    }]
  }
}

module "blog_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "${var.environment.name}-blog-alb"
  load_balancer_type = "application"
  vpc_id             = module.blog_vpc.vpc_id
  subnets            = module.blog_vpc.public_subnets
  security_groups    = [module.blog_sg.security_group_id]

  target_groups = [
    {
      name_prefix      = "blog-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      protocol_version = "HTTP1"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = var.environment.name
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id  = module.blog_vpc.vpc_id
  name    = "${var.environment.name}-blog-sg"
  
  ingress_rules = ["https-443-tcp", "http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  
  egress_rules = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}