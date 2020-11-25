output "bigip_admin_password_key" {
  value = module.bigip_password.secret_id
}
