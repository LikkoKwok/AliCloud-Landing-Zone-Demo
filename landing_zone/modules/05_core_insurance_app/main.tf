# ============================================
# DATA SOURCES
# ============================================
data "alicloud_zones" "available" {
  available_resource_creation = "VSwitch"
}

# ============================================
# SINGLE VPC FOR ALL 4 ENVIRONMENTS
# Requirement: All environments share same VPC but isolated via subnets + SGs
# ============================================
resource "alicloud_vpc" "core_insurance" {
  vpc_name   = "${var.environment}-core-insurance-vpc"
  cidr_block = var.core_insurance_vpc_cidr
  tags       = merge(var.tags, { 
    Tier = "core-insurance"
    Description = "Hosts all 4 environments: SIT, UAT, PreProd, Prod"
  })
  
  lifecycle {
    prevent_destroy = true
  }
}

# ============================================
# 4 ENVIRONMENTS - WEB SUBNETS
# Each environment gets its own isolated web subnet
# ============================================

# SIT Environment - Web
resource "alicloud_vswitch" "sit_web" {
  vpc_id       = alicloud_vpc.core_insurance.id
  cidr_block   = cidrsubnet(var.core_insurance_vpc_cidr, 8, 1)   # 10.1.1.0/24
  zone_id      = data.alicloud_zones.available.zones[0].id
  vswitch_name = "${var.environment}-sit-web"
  tags         = merge(var.tags, { Environment = "SIT", Tier = "web" })
}

# UAT Environment - Web
resource "alicloud_vswitch" "uat_web" {
  vpc_id       = alicloud_vpc.core_insurance.id
  cidr_block   = cidrsubnet(var.core_insurance_vpc_cidr, 8, 11)  # 10.1.11.0/24
  zone_id      = data.alicloud_zones.available.zones[0].id
  vswitch_name = "${var.environment}-uat-web"
  tags         = merge(var.tags, { Environment = "UAT", Tier = "web" })
}

# Pre-Production Environment - Web
resource "alicloud_vswitch" "preprod_web" {
  vpc_id       = alicloud_vpc.core_insurance.id
  cidr_block   = cidrsubnet(var.core_insurance_vpc_cidr, 8, 21)  # 10.1.21.0/24
  zone_id      = data.alicloud_zones.available.zones[0].id
  vswitch_name = "${var.environment}-preprod-web"
  tags         = merge(var.tags, { Environment = "PreProd", Tier = "web" })
}

# Production Environment - Web
resource "alicloud_vswitch" "prod_web" {
  vpc_id       = alicloud_vpc.core_insurance.id
  cidr_block   = cidrsubnet(var.core_insurance_vpc_cidr, 8, 31)  # 10.1.31.0/24
  zone_id      = data.alicloud_zones.available.zones[0].id
  vswitch_name = "${var.environment}-prod-web"
  tags         = merge(var.tags, { Environment = "Prod", Tier = "web" })
}

# ============================================
# 4 ENVIRONMENTS - DATABASE SUBNETS
# Each environment gets its own isolated DB subnet
# Only DB for Prod is set for Demo and Cost Saving purposes
# ============================================

# SIT Environment - Database
# resource "alicloud_vswitch" "sit_db" {
#   vpc_id       = alicloud_vpc.core_insurance.id
#   cidr_block   = cidrsubnet(var.core_insurance_vpc_cidr, 8, 2)   # 10.1.2.0/24
#   zone_id      = data.alicloud_zones.available.zones[0].id
#   vswitch_name = "${var.environment}-sit-db"
#   tags         = merge(var.tags, { Environment = "SIT", Tier = "database" })
# }

# UAT Environment - Database
# resource "alicloud_vswitch" "uat_db" {
#   vpc_id       = alicloud_vpc.core_insurance.id
#   cidr_block   = cidrsubnet(var.core_insurance_vpc_cidr, 8, 12)  # 10.1.12.0/24
#   zone_id      = data.alicloud_zones.available.zones[0].id
#   vswitch_name = "${var.environment}-uat-db"
#   tags         = merge(var.tags, { Environment = "UAT", Tier = "database" })
# }

# Pre-Production Environment - Database
# resource "alicloud_vswitch" "preprod_db" {
#   vpc_id       = alicloud_vpc.core_insurance.id
#   cidr_block   = cidrsubnet(var.core_insurance_vpc_cidr, 8, 22)  # 10.1.22.0/24
#   zone_id      = data.alicloud_zones.available.zones[0].id
#   vswitch_name = "${var.environment}-preprod-db"
#   tags         = merge(var.tags, { Environment = "PreProd", Tier = "database" })
# }

# Production Environment - Database
resource "alicloud_vswitch" "prod_db" {
  vpc_id       = alicloud_vpc.core_insurance.id
  cidr_block   = cidrsubnet(var.core_insurance_vpc_cidr, 8, 32)  # 10.1.32.0/24
  zone_id      = data.alicloud_zones.available.zones[0].id
  vswitch_name = "${var.environment}-prod-db"
  tags         = merge(var.tags, { Environment = "Prod", Tier = "database" })
}

# ============================================
# RESOURCE GROUPS PER ENVIRONMENT (Cost attribution)
# ============================================
resource "alicloud_resource_manager_resource_group" "insurance_sit" {
  resource_group_name = "rg-insurance-sit-${var.environment}"
  display_name        = "Insurance-SIT-${var.environment}"
}

resource "alicloud_resource_manager_resource_group" "insurance_uat" {
  resource_group_name = "rg-insurance-uat-${var.environment}"
  display_name        = "Insurance-UAT-${var.environment}"
}

resource "alicloud_resource_manager_resource_group" "insurance_preprod" {
  resource_group_name = "rg-insurance-preprod-${var.environment}"
  display_name        = "Insurance-PreProd-${var.environment}"
}

resource "alicloud_resource_manager_resource_group" "insurance_prod" {
  resource_group_name = "rg-insurance-prod-${var.environment}"
  display_name        = "Insurance-Prod-${var.environment}"
}

# ============================================
# ENCRYPTED RDS FOR EACH ENVIRONMENT
# Requirement: Each environment has isolated database
# Only RDS for Prod is created for Demo and Cost Saving purposes
# ============================================

# SIT Database
# resource "alicloud_db_instance" "core_sit" {
#   engine               = "SQLServer"
#   engine_version       = "2019_ent"
#   instance_type        = var.db_instance_class
#   instance_storage     = var.db_storage_gb
#   vswitch_id           = alicloud_vswitch.sit_db.id
#   instance_name        = "core-insurance-sit-db"
#   encryption_key       = var.kms_key_id
#   resource_group_id    = alicloud_resource_manager_resource_group.insurance_sit.id
#   tags                 = merge(var.tags, { Environment = "SIT" })
# }

# UAT Database
# resource "alicloud_db_instance" "core_uat" {
#   engine               = "SQLServer"
#   engine_version       = "2019_ent"
#   instance_type        = var.db_instance_class
#   instance_storage     = var.db_storage_gb
#   vswitch_id           = alicloud_vswitch.uat_db.id
#   instance_name        = "core-insurance-uat-db"
#   encryption_key       = var.kms_key_id
#   resource_group_id    = alicloud_resource_manager_resource_group.insurance_uat.id
#   tags                 = merge(var.tags, { Environment = "UAT" })
# }

# Pre-Production Database
# resource "alicloud_db_instance" "core_preprod" {
#   engine               = "SQLServer"
#   engine_version       = "2019_ent"
#   instance_type        = var.db_instance_class
#   instance_storage     = var.db_storage_gb
#   vswitch_id           = alicloud_vswitch.preprod_db.id
#   instance_name        = "core-insurance-preprod-db"
#   encryption_key       = var.kms_key_id
#   resource_group_id    = alicloud_resource_manager_resource_group.insurance_preprod.id
#   tags                 = merge(var.tags, { Environment = "PreProd" })
# }

# Production Database
resource "alicloud_db_instance" "core_prod" {
  count                = 0  # temporarily disable
  engine               = "SQLServer"
  engine_version       = "2019_ent"
  instance_type        = var.db_instance_class
  instance_storage     = var.db_storage_gb
  vswitch_id           = alicloud_vswitch.prod_db.id
  instance_name        = "core-insurance-prod-db"
  encryption_key       = var.kms_key_id
  resource_group_id    = alicloud_resource_manager_resource_group.insurance_prod.id
  tags                 = merge(var.tags, { Environment = "Prod" })
}

# ============================================
# ENCRYPTED OSS BUCKETS PER ENVIRONMENT
# ============================================

# create random string to ensure unique bucket names
resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "alicloud_oss_bucket" "app_data_sit" {
  bucket = "insurance-app-sit-${var.environment}-${random_string.bucket_suffix.result}"
  tags   = merge(var.tags, { Environment = "SIT" })
}

resource "alicloud_oss_bucket_server_side_encryption" "app_enc_sit" {
  bucket            = alicloud_oss_bucket.app_data_sit.bucket
  sse_algorithm     = "KMS"
  kms_master_key_id = var.kms_key_id
}

resource "alicloud_oss_bucket" "app_data_uat" {
  bucket = "insurance-app-uat-${var.environment}-${random_string.bucket_suffix.result}"
  tags   = merge(var.tags, { Environment = "UAT" })
}

resource "alicloud_oss_bucket_server_side_encryption" "app_enc_uat" {
  bucket            = alicloud_oss_bucket.app_data_uat.bucket
  sse_algorithm     = "KMS"
  kms_master_key_id = var.kms_key_id
}

resource "alicloud_oss_bucket" "app_data_preprod" {
  bucket = "insurance-app-preprod-${var.environment}-${random_string.bucket_suffix.result}"
  tags   = merge(var.tags, { Environment = "PreProd" })
}

resource "alicloud_oss_bucket_server_side_encryption" "app_enc_preprod" {
  bucket            = alicloud_oss_bucket.app_data_preprod.bucket
  sse_algorithm     = "KMS"
  kms_master_key_id = var.kms_key_id
}

resource "alicloud_oss_bucket" "app_data_prod" {
  bucket = "insurance-app-prod-${var.environment}-${random_string.bucket_suffix.result}"
  tags   = merge(var.tags, { Environment = "Prod" })
}

resource "alicloud_oss_bucket_server_side_encryption" "app_enc_prod" {
  bucket            = alicloud_oss_bucket.app_data_prod.bucket
  sse_algorithm     = "KMS"
  kms_master_key_id = var.kms_key_id
}


# ============================================
# ATTACH CORE INSURANCE VPC TO CEN
# ============================================
resource "alicloud_cen_transit_router_vpc_attachment" "core_insurance" {
  cen_id            = var.cen_id
  transit_router_id = var.transit_router_id
  vpc_id            = alicloud_vpc.core_insurance.id
  
  zone_mappings {
    zone_id    = data.alicloud_zones.available.zones[0].id
    vswitch_id = alicloud_vswitch.prod_web.id  # Representative subnet for attachment
  }
}