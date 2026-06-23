# output "saml_provider_arn" {
#   value = alicloud_ram_saml_provider.azure_ad.arn
# }

# output "federated_role_arns" {
#   value = { for k, r in alicloud_ram_role.federated : k => r.arn }
# }

output "ai_app_service_role_arn" {
  value = alicloud_ram_role.ai_app_service.arn
}

