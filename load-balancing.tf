# ---------------------------------------------------------------------------------------------------------------------
# AWS SECURITY GROUP - Control Access to ALB
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "lb_sg" {
  name        = "${var.name_preffix}-lb-sg"
  description = "Control access to LB"
  vpc_id      = var.vpc_id
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name_preffix}-lb-sg"
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# AWS LOAD BALANCER
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lb" "lb" {
  name                             = "${var.name_preffix}-lb"
  internal                         = false
  load_balancer_type               = "application"
  subnets                          = var.public_subnets
  security_groups                  = [aws_security_group.lb_sg.id]
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  tags = {
    Name = "${var.name_preffix}-lb"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AWS LOAD BALANCER - Target Group
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lb_target_group" "lb_tg" {
  depends_on           = [aws_lb.lb]
  name                 = "${var.name_preffix}-lb-tg"
  target_type          = "ip"
  protocol             = "HTTP"
  port                 = var.container_port
  vpc_id               = var.vpc_id
  deregistration_delay = 0
  health_check {
    path = var.health_check_path
    port = var.container_port
  }
  tags = {
    Name = "${var.name_preffix}-lb-tg"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AWS LOAD BALANCER -  Listener
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lb_listener" "listener" {
  depends_on        = [aws_lb_target_group.lb_tg]
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.lb_tg.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "listener_https" {

  count             = var.enable_https == true ? 1 : 0
  depends_on        = [aws_lb_target_group.lb_tg]
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}
