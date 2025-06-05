module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "ivi-webserver-kp"
  create_private_key = true
}

module "sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "ivi-webserver"
  description = "Security group for web-server with HTTP ports open within VPC"
  vpc_id      = "vpc-0938f895360ba7719"

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Owner       = "Ivi"
  }
}

module "ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "ivi-webserver"

  instance_type          = "t2.small"
  ami                    = "ami-0ae9f87d24d606be4"
  key_name               = module.key_pair.key_pair_name
  monitoring             = true
  vpc_security_group_ids = [module.sg.security_group_id]
  subnet_id              = "subnet-0490c1f1247471213" # ivi-private-us-east-2a

  user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo apt update -y
  sudo apt install apache2 -y
  echo "*** Completed Installing apache2"
  EOF

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Owner       = "Ivi"
  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "ivi-webserver-alb"
  vpc_id  = "vpc-0938f895360ba7719"
  subnets = ["subnet-0d2efbc0b2dcf948c", "subnet-061327b73a116fb12"]

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  #   access_logs = {
  #     bucket = "my-alb-logs"
  #   }

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    # ex-https = {
    #   port            = 443
    #   protocol        = "HTTPS"
    #   certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"

    #   forward = {
    #     target_group_key = "ex-instance"
    #   }
    # }
  }

  target_groups = {
    ex-instance = {
      name_prefix = "h1"
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"
      target_id   = module.ec2.id
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Owner       = "Ivi"
  }
}
