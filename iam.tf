data "aws_iam_policy_document" "bastion_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "bastion" {
  name_prefix        = "${var.name_prefix}bastion"
  assume_role_policy = data.aws_iam_policy_document.bastion_assume_role.json
}

data "aws_iam_policy_document" "bastion_policy" {
  # Allow downloading of user SSH public keys
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.ssh_keys.arn}/*"]
    effect    = "Allow"
  }

  # Allow listing SSH public keys
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.ssh_keys.arn]
  }
}

resource "aws_iam_policy" "bastion" {
  name_prefix = "${var.name_prefix}bastion"
  policy      = data.aws_iam_policy_document.bastion_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_given_policy" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion.arn
}

resource "aws_iam_instance_profile" "bastion_host_profile" {
  name_prefix = "${var.name_prefix}bastion-profile"
  role        = aws_iam_role.bastion.name
}