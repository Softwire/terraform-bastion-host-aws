output "instances_security_group_id" {
  value = aws_security_group.instances.id
}

output "bastion_dns_name" {
  value = aws_lb.bastion.dns_name
}

output "ssh_keys_bucket" {
  value = aws_s3_bucket.ssh_keys.bucket
}
