# This is where the SSH keys of users will be stored
resource "aws_s3_bucket" "ssh_keys" {
  bucket_prefix = "${var.name_prefix}ssh-keys"
}

resource "aws_s3_bucket_acl" "ssh_keys_acl" {
  bucket = aws_s3_bucket.ssh_keys.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "ssh_keys_versioning" {
  bucket = aws_s3_bucket.ssh_keys.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "ssh_keys_readme" {
  bucket  = aws_s3_bucket.ssh_keys.id
  key     = "README.txt"
  content = "Drop public SSH keys of users who require access to the bastion. The filename (without the .pub) will be their username."
}
