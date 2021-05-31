resource "aws_security_group" "lb_sg" {
  name        = "lb-${var.name}-sg"
  description = "Allow Internet inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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
  port              = "80"
  protocol          = "HTTP"

 default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target.arn
  }

}

resource "aws_lb_target_group" "lb_target" {
  name        = "lb-${var.name}-target"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id


    health_check {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/healthcheck"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
    }

}

output "lb_target_arn" {
  value = aws_lb_target_group.lb_target.arn
}
