# output "resource_directory_id" {
#   value = module.master_account.resource_directory_id
# }

# output "saml_provider_arn" {
#   value = module.identity_sso.saml_provider_arn
# }

output "hub_vpc_id" {
  value = module.hub_security.hub_vpc_id
}

output "transit_router_id" {
  value = module.hub_security.transit_router_id
}

output "central_logstore" {
  value = module.logging_account.logstore_name
}

output "app_vpc_id" {
  value = module.core_insurance_app.vpc_id
}
