output "sls_project_name" {
  value = alicloud_log_project.central.project_name
}

output "logstore_name" {
  value = alicloud_log_store.audit.logstore_name
}

output "ai_logstore_name" {
  value = alicloud_log_store.ai_ops.logstore_name
}

output "config_aggregator_id" {
  value = alicloud_config_aggregator.org.id
}

# output "actiontrail_role_arn" {
#   value = alicloud_ram_role.actiontrail_sls.arn
# }
