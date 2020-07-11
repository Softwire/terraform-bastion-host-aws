# Use the latest Amazon Linux 2 EBS image by default
data "aws_ami" "aws_linux_2" {
  count       = var.custom_ami != "" ? 0 : 1
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "^amzn2-ami-hvm-2.0.*"

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_security_group" "bastion" {
  description = "Enable SSH access to the bastion host from external via SSH port"
  name        = "${var.name_prefix}main"
  vpc_id      = var.vpc_id

  tags = merge(map("Name", "${var.name_prefix}main"), var.tags_default, var.tags_sg)

  # Incoming traffic from the internet. Only allow SSH connections
  ingress {
    from_port   = var.external_ssh_port
    to_port     = var.external_ssh_port
    protocol    = "TCP"
    cidr_blocks = concat(data.aws_subnet.subnets.*.cidr_block, var.external_allowed_cidrs)
  }

  # Outgoing traffic - restrict to the VPC
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.bastion.cidr_block]
  }
}

resource "aws_security_group" "instances" {
  description = "Apply this group to specific instances to allow SSH ingress from the bastion"
  name        = "${var.name_prefix}instances"
  vpc_id      = var.vpc_id

  tags = merge(map("Name", "${var.name_prefix}instances"), var.tags_default, var.tags_sg)

  # Incoming traffic from the internet. Only allow SSH connections
  ingress {
    from_port       = var.internal_ssh_port
    to_port         = var.internal_ssh_port
    protocol        = "TCP"
    security_groups = [aws_security_group.bastion.id]
  }
}

resource "aws_launch_configuration" "bastion" {
  name_prefix = "${var.name_prefix}launch-config-"
  image_id    = var.custom_ami != "" ? var.custom_ami : data.aws_ami.aws_linux_2[0].image_id
  # A t2.nano should be perfectly sufficient for a simple bastion host
  instance_type               = "t2.nano"
  associate_public_ip_address = false
  enable_monitoring           = true
  iam_instance_profile        = aws_iam_instance_profile.bastion_host_profile.name
  key_name                    = var.admin_ssh_key_pair

  security_groups = [aws_security_group.bastion.id]

  user_data = templatefile("${path.module}/init.sh", {
    region      = var.region
    bucket_name = aws_s3_bucket.ssh_keys.bucket
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  name_prefix          = "${var.name_prefix}asg-"
  launch_configuration = aws_launch_configuration.bastion.name
  max_size             = local.instance_count
  min_size             = local.instance_count
  desired_capacity     = local.instance_count

  vpc_zone_identifier = var.subnet_arns

  default_cooldown          = 180
  health_check_grace_period = 180
  health_check_type         = "EC2"

  target_group_arns = [
    aws_lb_target_group.bastion_default.arn,
  ]

  termination_policies = [
    "OldestLaunchConfiguration",
  ]

  dynamic tag {
    for_each = merge(map("Name", "${var.name_prefix}asg"), var.tags_default, var.tags_asg)
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
