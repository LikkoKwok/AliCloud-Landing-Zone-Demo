locals {
  base_tags = merge(var.common_tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "LandingZone"
  })
}

# ============================================
# DISABLED: Master Account Module
# Reason: Resource Directory already exists and member accounts are created manually
# ============================================
# module "master_account" {
#   source      = "./modules/01_master_account"
#   environment = var.environment
#   tags        = local.base_tags
#   providers   = { alicloud = alicloud.master }
# }

module "identity_sso" {
  source                = "./modules/02_identity_sso"
  azure_ad_metadata_url = var.azure_ad_metadata_url
  tags                  = local.base_tags
  providers             = { alicloud = alicloud.master }
}

# Hub Security Module (Palo Alto + WAF + CEN)
module "hub_security" {
  source                  = "./modules/03_hub_security"
  environment             = var.environment
  region                  = var.region
  secondary_region        = var.secondary_region
  hub_vpc_cidr            = var.hub_vpc_cidr
  inbound_redirect_cidrs = [var.core_insurance_vpc_cidr, var.ai_lab_vpc_cidr,]
  transit_router_id       = var.transit_router_id
  firewall_instance_type  = var.firewall_instance_type
  backbone_bandwidth_mbps = var.backbone_bandwidth_mbps
  az_count                = var.az_count
  tags                    = local.base_tags
  providers = {
    alicloud           = alicloud.hub
    alicloud.singapore = alicloud.singapore
  }
}

# Shared Service Module (CyberArk + Unified Ingress + AI Gateway + Ops Bastion)
module "shared_service" {
  source             = "./modules/04_cyberark_bastion"
  environment        = var.environment
  shared_service_vpc_cidr = var.shared_service_vpc_cidr
  management_vpc_cidr = var.management_vpc_cidr
  region             = var.region
  az_count           = var.az_count
  instance_type      = var.bastion_instance_type
  hub_vpc_id         = module.hub_security.hub_vpc_id
  cen_id             = module.hub_security.cen_id
  transit_router_id  = module.hub_security.transit_router_id
  tags               = local.base_tags
  providers          = { alicloud = alicloud.shared }
}


# Update core_insurance_app module to receive palo_alto_trust_eni_id
module "core_insurance_app" {
  source         = "./modules/05_core_insurance_app"
  environment        = var.environment
  management_vpc_cidr = var.management_vpc_cidr
  core_insurance_vpc_cidr = var.core_insurance_vpc_cidr
  transit_router = module.hub_security.transit_router_id
  cen_id         = module.hub_security.cen_id
  kms_key_id     = module.hub_security.kms_key_id
  palo_alto_trust_eni_id = module.hub_security.palo_alto_trust_eni_id
  tags           = local.base_tags
  providers      = { alicloud = alicloud.app }
}

module "pai_platform" {
  source            = "./modules/06_pai_platform"
  count             = var.enable_gpu_cluster ? 1 : 0
  environment       = var.environment
  vpc_cidr          = var.ai_lab_vpc_cidr
  hub_vpc_id        = module.hub_security.hub_vpc_id
  gpu_instance_type = var.gpu_instance_type
  kms_key_id        = module.hub_security.kms_key_id
  tags              = local.base_tags
  providers         = { alicloud = alicloud.ai_training }
}

module "ai_data_security" {
  source      = "./modules/07_ai_data_security"
  environment = var.environment
  kms_key_id  = module.hub_security.kms_key_id
  tags        = local.base_tags
  providers   = { alicloud = alicloud.ai_training }
}

module "ai_guardrails" {
  source      = "./modules/08_ai_guardrails"
  environment = var.environment
  tags        = local.base_tags
  providers   = { alicloud = alicloud.ai_training }
}

module "financial_governance" {
  source      = "./modules/09_financial_governance"
  environment = var.environment
  tags        = local.base_tags
  providers   = { alicloud = alicloud.master }
}

# Logging Account Module
module "logging_account" {
  source             = "./modules/10_logging_account"
  environment        = var.environment
  log_retention_days = var.log_retention_days
  tags               = local.base_tags
  providers          = { alicloud = alicloud.log }
}

module "model_governance" {
  source      = "./modules/11_model_governance"
  environment = var.environment
  kms_key_id  = module.hub_security.kms_key_id
  tags        = local.base_tags
  providers   = { alicloud = alicloud.ai_inference }
}

module "observability" {
  source        = "./modules/12_observability"
  environment   = var.environment
  sls_project   = module.logging_account.sls_project_name
  tags          = local.base_tags
  providers     = { alicloud = alicloud.log }
}
