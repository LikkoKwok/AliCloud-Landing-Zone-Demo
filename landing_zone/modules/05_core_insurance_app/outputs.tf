# Change from references to webapp/internal to core_insurance
output "vpc_id" {
  value = alicloud_vpc.core_insurance.id
}

output "internal_vpc_id" {
  value = alicloud_vpc.core_insurance.id
}

output "resource_group_id" {
  value = alicloud_resource_manager_resource_group.insurance_prod.id
}

output "db_connection" {
  value = length(alicloud_db_instance.core_prod) > 0 ? alicloud_db_instance.core_prod[0].connection_string : ""
}