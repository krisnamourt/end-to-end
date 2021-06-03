resource "aws_security_group" "lb_sg" {
  name        = "lb-${var.name}-sg"
  description = "Allow Internet inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.public_port
    to_port     = var.public_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "task_sg" {
  name        = "task-${var.name}-sg"
  description = "Allow Internet inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.private_port
    to_port     = var.private_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "app_role" {
  name = "api-python-role"

  assume_role_policy = file("${path.module}/base_role.json")

}

resource "aws_iam_policy" "policy" {
  name        = "api-python-policy"
  description = "Db migrate flyway execution policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DescribeTargetGroups",  
        "elasticloadbalancing:DescribeTargetHealth",          
        "ec2:DescribeInstances",
        "secretsmanager:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "role-policy" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_lb" "lb_app" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = var.subnets

  enable_deletion_protection = false
}



resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb_app.arn
  port              = "${var.public_port}"
  protocol          = "HTTP"

 default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target.arn
  }

}

resource "aws_lb_target_group" "lb_target" {
  name        = "lb-${var.name}-target"
  port        = var.public_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id


    health_check {
        enabled             = true
        healthy_threshold   = 5
        interval            = 45
        matcher             = "200"
        path                = "/healthcheck"
        port                = "${var.private_port}"
        protocol            = "HTTP"
        timeout             = 15
        unhealthy_threshold = 5
    }

}

output "lb_target_arn" {
  value = aws_lb_target_group.lb_target.arn
}

output "sg_public" {
  value = aws_security_group.lb_sg.id
}

output "sg_private" {
  value = aws_security_group.task_sg.id
}

output "app_role" {
  value = aws_iam_role.app_role.name
}
