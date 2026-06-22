# Azure Entra ID as SAML IdP (to be provided)
resource "alicloud_ram_saml_provider" "azure_ad" {
  saml_provider_name             = "AzureEntraID-SSO"
  description                    = "Azure Entra ID SAML federation"
  encodedsaml_metadata_document  = filebase64("azure_ad_metadata.xml")
}

locals {
  ai_roles = {
    ai-platform-admin = "AliyunPAIFullAccess"
    ml-engineer       = "AliyunPAIDeveloperAccess"
    data-scientist    = "AliyunOSSReadOnlyAccess"
    model-reviewer    = "AliyunPAIReadOnlyAccess"
    ai-auditor        = "AliyunActionTrailReadOnlyAccess"
  }
  infra_roles = {
    cloud-admin   = "AdministratorAccess"
    dba           = "AliyunRDSFullAccess"
    network-admin = "AliyunVPCFullAccess"
  }
}

resource "alicloud_ram_role" "federated" {
  for_each    = merge(local.ai_roles, local.infra_roles)
  role_name   = "sso-${each.key}"
  description = "Federated least-privilege role for ${each.key}"

  assume_role_policy_document = jsonencode({
    Version = "1"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Federated = [alicloud_ram_saml_provider.azure_ad.arn] }
      Condition = {
        StringEquals = { "saml:recipient" = "https://signin.alibabacloud.com/saml-role/sso" }
      }
    }]
  })

  max_session_duration = 3600
}

resource "alicloud_ram_role_policy_attachment" "attach" {
  for_each    = merge(local.ai_roles, local.infra_roles)
  role_name   = alicloud_ram_role.federated[each.key].role_name
  policy_name = each.value
  policy_type = "System"
}

# Per-application service role for AI model invocation (not per individual)
resource "alicloud_ram_role" "ai_app_service" {
  role_name   = "ai-claims-app-invoke"
  description = "Per-application model invocation role; temp creds only"

  assume_role_policy_document = jsonencode({
    Version = "1"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = ["ecs.aliyuncs.com"] }
    }]
  })

  max_session_duration = 3600
}

# NOTE: API keys live in self-purchased KMS, rotated every 90 days externally.
