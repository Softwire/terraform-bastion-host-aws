output "bastion_security_group_id" {
  description = "Security group of the bastion instances"
  value       = aws_security_group.bastion.id
}

output "bastion_dns_name" {
  value = aws_lb.bastion.dns_name
}

output "ssh_keys_bucket" {
  value = aws_s3_bucket.ssh_keys.bucket
}

output "bastion_host_key_fingerprint_sha256" {
  value = tls_private_key.bastion_host_key.public_key_fingerprint_sha256
}
