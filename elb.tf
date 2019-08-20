resource "aws_lb" "bastion" {
  name_prefix = "${var.name_prefix}lb-"
  internal    = false

  subnets = var.subnet_arns

  load_balancer_type = "network"
  tags               = merge(map("Name", "${var.name_prefix}lb"), var.tags_default, var.tags_lb)
}

resource "aws_lb_target_group" "bastion_default" {
  vpc_id = var.vpc_id

  port        = var.external_ssh_port
  protocol    = "TCP"
  target_type = "instance"

  health_check {
    port     = "traffic-port"
    protocol = "TCP"
  }

  tags = merge(map("Name", "${var.name_prefix}lb"), var.tags_default, var.tags_lb)
}

resource "aws_lb_listener" "bastion_ssh" {
  load_balancer_arn = aws_lb.bastion.arn
  port              = var.external_ssh_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.bastion_default.arn
    type             = "forward"
  }
}