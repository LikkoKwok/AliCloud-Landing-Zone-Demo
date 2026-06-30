# Role for ACK AutoScaler component
resource "alicloud_ram_role" "cs_auto_scaler" {
  role_name        = "AliyunCSManagedAutoScalerRole"
  description = "ACK auto scaling component role"
  assume_role_policy_document     = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = ["cs.aliyuncs.com"]
      }
    }]
    Version   = "1"
  })
}

# Attach the required policy
resource "alicloud_ram_role_policy_attachment" "cs_auto_scaler_policy" {
  role_name   = alicloud_ram_role.cs_auto_scaler.role_name
  policy_name = "AliyunCSManagedAutoScalerRolePolicy"
  policy_type = "System"
}

# ============================================
# PAI WORKSPACES (AI Innovation Lab OU)
# Requirement: Isolate Claims and Actuarial teams
# ============================================

resource "random_string" "pai_suffix" {
  length  = 4
  special = false
  upper   = false
  lower   = true
  numeric = true
}

# Claims Team Workspace
resource "alicloud_pai_workspace_workspace" "claims" {
  description    = "Workspace for Claims AI team - Intelligent Claims Processing"
  workspace_name = "claims${random_string.pai_suffix.result}"
  display_name   = "Claims AI Workspace"
  env_types      = ["prod"]
}

# Actuarial Team Workspace
resource "alicloud_pai_workspace_workspace" "actuarial" {
  description    = "Workspace for Actuarial AI team - Risk Modeling"
  workspace_name = "actuarial${random_string.pai_suffix.result}"
  display_name   = "Actuarial AI Workspace"
  env_types      = ["prod"]
}

# ============================================
# PAI DATASETS (for Document Digitization & RAG)
# Requirement: Training data for OCR and claims processing
# ============================================

# Dataset for OCR processed data
resource "alicloud_pai_workspace_dataset" "claims_ocr_data" {
  dataset_name = "claims-ocr-data-${var.environment}-${random_string.pai_suffix.result}"
  data_source_type = "OSS"
  uri              = "oss://${alicloud_oss_bucket.training_data.bucket}/ocr-processed/"
  property         = "DIRECTORY"
  workspace_id     = alicloud_pai_workspace_workspace.claims.id
  description      = "Processed OCR data for Intelligent Claims Processing"
}

# Dataset for Actuarial training data
resource "alicloud_pai_workspace_dataset" "actuarial_data" {
  dataset_name     = "actuarial-training-data-${var.environment}-${random_string.pai_suffix.result}"
  data_source_type = "OSS"
  uri              = "oss://${alicloud_oss_bucket.training_data.bucket}/actuarial/"
  property         = "DIRECTORY"
  workspace_id     = alicloud_pai_workspace_workspace.actuarial.id
  description      = "Actuarial risk modeling training data"
}

# ============================================
# PAI EXPERIMENTS (Actuarial Risk Modeling - PAI DLC)
# ============================================

# Experiment for tracking Actuarial Risk Modeling
resource "alicloud_pai_workspace_experiment" "actuarial_exp" {
  experiment_name = "actuarial-risk-modeling-${var.environment}-${random_string.pai_suffix.result}"
  workspace_id    = alicloud_pai_workspace_workspace.actuarial.id
  artifact_uri    = "oss://${alicloud_oss_bucket.training_data.bucket}/experiments/"
}

# ============================================
# PAI MODELS (Model Registry)
# ============================================

# Model registration for Claims LLM
resource "alicloud_pai_workspace_model" "claims_llm" {
  model_name     = "claims-llm-model-${var.environment}-${random_string.pai_suffix.result}"
  workspace_id   = alicloud_pai_workspace_workspace.claims.id
  accessibility  = "PRIVATE"
  model_type     = "Checkpoint"
  task           = "text-generation"
  domain         = "nlp"
  model_doc      = "oss://${alicloud_oss_bucket.training_data.bucket}/models/claims-llm/README.md"
  labels {
    key   = "framework"
    value = "pytorch"
  }
  labels {
    key   = "model-family"
    value = "qwen"
  }
}

# ============================================
# AI LAB VPC & NETWORK (Infrastructure for AI Workloads)
# ============================================

data "alicloud_zones" "available" {
  available_resource_creation = "VSwitch"
}

# Dedicated VPC for AI workloads
resource "alicloud_vpc" "ai" {
  vpc_name   = "ai-lab-vpc"
  cidr_block = var.ai_lab_vpc_cidr
  tags       = merge(var.tags, { Workload = "AI" })
}

# Subnets for different AI functions
resource "alicloud_vswitch" "data" {
  vpc_id       = alicloud_vpc.ai.id
  cidr_block   = cidrsubnet(var.ai_lab_vpc_cidr, 8, 1)   # 10.2.1.0/24
  zone_id      = data.alicloud_zones.available.zones[0].id
  vswitch_name = "ai-data"
  tags         = var.tags
}

resource "alicloud_vswitch" "training" {
  vpc_id       = alicloud_vpc.ai.id
  cidr_block   = cidrsubnet(var.ai_lab_vpc_cidr, 8, 2)   # 10.2.2.0/24
  zone_id      = data.alicloud_zones.available.zones[0].id
  vswitch_name = "ai-training"
  tags         = merge(var.tags, { Network = "RDMA-ready" })
}

resource "alicloud_vswitch" "inference" {
  vpc_id       = alicloud_vpc.ai.id
  cidr_block   = cidrsubnet(var.ai_lab_vpc_cidr, 8, 3)   # 10.2.3.0/24
  zone_id      = data.alicloud_zones.available.zones[0].id
  vswitch_name = "ai-inference"
  tags         = var.tags
}

# Resource Groups for cost attribution (Claims vs Actuarial)
resource "alicloud_resource_manager_resource_group" "claims" {
  resource_group_name = "rg-ai-claims-${var.environment}"
  display_name        = "AI-Claims-${var.environment}"
}

resource "alicloud_resource_manager_resource_group" "actuarial" {
  resource_group_name = "rg-ai-actuarial-${var.environment}"
  display_name        = "AI-Actuarial-${var.environment}"
}

# Low-cost OSS bucket for training data and models (for Demo purposes)
resource "alicloud_oss_bucket" "training_data" {
  bucket = "ai-training-data-${random_string.pai_suffix.result}"
  tags   = merge(var.tags, { DataClass = "sensitive" })
}

resource "alicloud_oss_bucket_server_side_encryption" "training_enc" {
  bucket            = alicloud_oss_bucket.training_data.bucket
  sse_algorithm     = "KMS"
  kms_master_key_id = var.kms_key_id
}

# ============================================
# ATTACH AI LAB VPC TO CEN
# ============================================

resource "alicloud_cen_transit_router_vpc_attachment" "ai_lab" {
  cen_id            = var.cen_id
  transit_router_id = var.transit_router_id
  vpc_id            = alicloud_vpc.ai.id
  auto_publish_route_enabled = true  # KEEPS ROUTE SYNCHRONIZATION ENABLED

  lifecycle {
    prevent_destroy = false
  }

  zone_mappings {
    zone_id    = data.alicloud_zones.available.zones[0].id
    vswitch_id = alicloud_vswitch.data.id  # use data subnet
  }
}