# This is where the SSH keys of users will be stored
resource "aws_s3_bucket" "ssh_keys" {
  bucket_prefix = "${var.name_prefix}ssh-keys"
  acl           = "private"
  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_object" "ssh_keys_readme" {
  bucket  = aws_s3_bucket.ssh_keys.id
  key     = "README.txt"
  content = "Drop public SSH keys of users who require access to the bastion. The filename (without the .pub) will be their username."
}