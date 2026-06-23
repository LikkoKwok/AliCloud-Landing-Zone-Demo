# Central SLS project + immutable logstore
resource "alicloud_log_project" "central" {
  project_name = "central-audit-${var.environment}-v2"
  description  = "Central audit log store (3yr retention)"
  tags         = var.tags
  lifecycle {
    prevent_destroy = true
  }
}


resource "alicloud_log_store" "audit" {
  project_name          = alicloud_log_project.central.project_name
  logstore_name         = "cloud-operations"
  retention_period      = var.log_retention_days
  shard_count           = 2
  auto_split            = true
  max_split_shard_count = 8
}

# Dedicated logstore for AI platform operations (same central store, separate stream)
resource "alicloud_log_store" "ai_ops" {
  project_name          = alicloud_log_project.central.project_name
  logstore_name         = "ai-operations"
  retention_period      = var.log_retention_days
  shard_count           = 2
  auto_split            = true
  max_split_shard_count = 8
}

# Role allowing ActionTrail to write into SLS
# resource "alicloud_ram_role" "actiontrail_sls" {
#  role_name = "actiontrail-to-sls-${var.environment}"
#
#  assume_role_policy_document = jsonencode({
#    Version = "1"
#    Statement = [{
#      Action    = "sts:AssumeRole"
#      Effect    = "Allow"
#      Principal = { Service = ["actiontrail.aliyuncs.com"] }
#    }]
#  })
#  max_session_duration = 3600
# }

# resource "alicloud_ram_role_policy_attachment" "actiontrail_log" {
#   role_name   = alicloud_ram_role.actiontrail_sls.role_name
#   policy_name = "AliyunLogFullAccess"
#   policy_type = "System"
# }

# Multi-account ActionTrail delivering ALL API calls (incl. AI platforms) to SLS
resource "alicloud_actiontrail_trail" "org" {
  trail_name         = "org-multi-account-trail-${var.environment}"
  sls_project_arn    = "acs:log:${var.region}:${var.account_id}:project/${alicloud_log_project.central.project_name}"
# sls_write_role_arn = alicloud_ram_role.actiontrail_sls.arn
  trail_region       = "All"
  event_rw           = "All"
}

# Cloud Config multi-account aggregator (RD-wide)
resource "alicloud_config_aggregator" "org" {
  aggregator_name = "org-aggregator-${var.environment}"
  aggregator_type = "RD"
  description     = "Organization-wide compliance aggregator"
}

# --- CIS / regulatory baseline compliance rules ---

resource "alicloud_config_rule" "unencrypted_disk" {
  rule_name                 = "ecs-disk-encryption-check"
  source_owner              = "ALIYUN"
  source_identifier         = "ecs-disk-encrypted"
  resource_types_scope      = ["ACS::ECS::Disk"]
  risk_level                = 1
  config_rule_trigger_types = "ConfigurationItemChangeNotification"
}

resource "alicloud_config_rule" "oss_encryption" {
  rule_name                 = "oss-bucket-encryption-check"
  source_owner              = "ALIYUN"
  source_identifier         = "oss-bucket-server-side-encryption-enabled"
  resource_types_scope      = ["ACS::OSS::Bucket"]
  risk_level                = 1
  config_rule_trigger_types = "ConfigurationItemChangeNotification"
}

resource "alicloud_config_rule" "rds_encryption" {
  count                     = 0
  rule_name                 = "rds-tde-check"
  source_owner              = "ALIYUN"
  source_identifier         = "rds-tde-enabled"
  resource_types_scope      = ["ACS::RDS::DBInstance"]
  risk_level                = 1
  config_rule_trigger_types = "ConfigurationItemChangeNotification"
}

resource "alicloud_config_rule" "slb_https" {
  count                     = 0
  rule_name                 = "slb-listener-https-check"
  source_owner              = "ALIYUN"
  source_identifier         = "slb-listener-https-check"
  resource_types_scope      = ["ACS::SLB::LoadBalancer"]
  risk_level                = 2
  config_rule_trigger_types = "ConfigurationItemChangeNotification"
}

# --- AI-specific compliance rule: inference endpoints must not be public ---
resource "alicloud_config_rule" "no_public_inference" {
  rule_name                 = "ai-inference-no-public-ip"
  source_owner              = "ALIYUN"
  source_identifier         = "ecs-instance-no-public-ip"
  resource_types_scope      = ["ACS::ECS::Instance"]
  risk_level                = 1
  config_rule_trigger_types = "ConfigurationItemChangeNotification"
  exclude_resource_ids_scope = ""
  # Scope to the AI inference resource group via tag in production.
}
