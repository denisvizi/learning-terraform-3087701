data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [module.blog_sg.security_group_id]
  subnet_id             = module.blog_vpc.public_subnets[0]

  tags = {
    Name = "Learning Terraform"
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"  # Use version 8.x which has a more stable interface

  name    = "blog-alb"
  vpc_id  = module.blog_vpc.vpc_id
  subnets = module.blog_vpc.public_subnets
  security_groups = [module.blog_sg.security_group_id]

  # Target group configuration - using list format for version 8.x
  target_groups = [
    {
      name_prefix      = "blog-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      
      # Health check configuration
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]

  # Listener configuration - using list format for version 8.x
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "dev"
  }
}

# Target group attachment
resource "aws_lb_target_group_attachment" "blog" {
  target_group_arn = module.alb.target_group_arns[0]
  target_id        = aws_instance.blog.id
  port             = 80
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"
  name    = "blog"

  vpc_id              = module.blog_vpc.vpc_id
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
}