# Azure Entra ID as SAML IdP (to be provided)
# resource "alicloud_ram_saml_provider" "azure_ad" {
#   saml_provider_name             = "AzureEntraID-SSO"
#   description                    = "Azure Entra ID SAML federation"
#   encodedsaml_metadata_document  = filebase64("${path.module}/azure_ad_metadata.xml")
# }

# ============================================
# Suggested RBAC roles
# ============================================

locals {
  # AI & Data Roles
  ai_roles = {
    "ai-platform-admin" = "AliyunPAIFullAccess"           # AI Lab
    "ml-engineer"       = ["AliyunPAIFullAccess","AliyunOSSReadOnlyAccess"]    # AI Training
    "data-scientist"    = ["AliyunPAIFullAccess","AliyunOSSReadOnlyAccess"]    # Access to PAI DLC and OSS containing training data
    "model-reviewer"    = "AliyunPAIReadOnlyAccess"       # AI Inference
    "ai-user"           = "AliyunPAIReadOnlyAccess"       # Access to PAI EAS
    "ai-auditor"        = "AliyunActionTrailReadOnlyAccess" # Logging
  }

  # Infrastructure Roles
  infra_roles = {
    "cloud-admin"   = "AdministratorAccess"               # Master Account
    "network-admin" = "AliyunVPCFullAccess"               # Hub Security
    "dba"           = "AliyunRDSFullAccess"               # Core Insurance App
  }
}

# ============================================
# FEDERATED ROLES (SAML-based SSO)
# ============================================

resource "alicloud_ram_role" "federated" {
  for_each = merge(local.ai_roles, local.infra_roles)

  role_name   = "sso-${each.key}"
  description = "Federated least-privilege role for ${each.key}"

  assume_role_policy_document = jsonencode({
    Version = "1"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Federated = [alicloud_ram_saml_provider.azure_ad.arn]
      }
      Condition = {
        StringEquals = {
          "saml:recipient" = "https://signin.aliyun.com/saml-role/sso"
        }
      }
    }]
  })

  max_session_duration = 3600
}

# ============================================
# ATTACH SYSTEM POLICIES TO ROLES
# ============================================

resource "alicloud_ram_role_policy_attachment" "attach" {
  for_each = merge(local.ai_roles, local.infra_roles)

  role_name   = alicloud_ram_role.federated[each.key].role_name
  policy_name = each.value
  policy_type = "System"
}

# ============================================
# PER-APPLICATION SERVICE ROLE (AI Model Invocation)
# ============================================

resource "alicloud_ram_role" "ai_app_service" {
  role_name   = "ai-claims-app-invoke"
  description = "Per-application model invocation role; temp creds only"

  assume_role_policy_document = jsonencode({
    Version = "1"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = ["ecs.aliyuncs.com"]
      }
    }]
  })

  max_session_duration = 3600
}

# NOTE: API keys live in self-purchased KMS, rotated every 90 days externally.
