output "ssh_key" {
  value = tls_private_key.ssh_key
}

output "public_key_openssh" {
  value     = tls_private_key.ssh_key.public_key_openssh
  sensitive = true
}

output "public_key_pem" {
  value     = tls_private_key.ssh_key.public_key_pem
  sensitive = true
}


output "private_key_openssh" {
  value     = tls_private_key.ssh_key.private_key_openssh
  sensitive = true
}

output "private_key_pem" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

