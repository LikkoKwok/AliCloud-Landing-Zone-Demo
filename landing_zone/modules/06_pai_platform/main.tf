# ============================================
# PAI WORKSPACES (AI Innovation Lab OU)
# Requirement: Isolate Claims and Actuarial teams
# ============================================

resource "random_string" "pai_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Claims Team Workspace
resource "alicloud_pai_workspace_workspace" "claims" {
  description    = "Workspace for Claims AI team - Intelligent Claims Processing"
  workspace_name = "claims-ai-workspace-${var.environment}-${random_string.pai_suffix.result}"
  display_name   = "Claims AI Workspace (${var.environment})"
  env_types      = ["prod"]
}

# Actuarial Team Workspace
resource "alicloud_pai_workspace_workspace" "actuarial" {
  description    = "Workspace for Actuarial AI team - Risk Modeling"
  workspace_name = "actuarial-ai-workspace-${var.environment}-${random_string.pai_suffix.result}"
  display_name   = "Actuarial AI Workspace (${var.environment})"
  env_types      = ["prod"]
}

# ============================================
# PAI DATASETS (for Document Digitization)
# Requirement: Training data for OCR and claims processing
# ============================================

# Dataset for OCR processed data (Document Digitization)
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
# PAI EXPERIMENTS & RUNS (Actuarial Risk Modeling - PAI DLC)
# ============================================

# Experiment for Actuarial Risk Modeling
resource "alicloud_pai_workspace_experiment" "actuarial_exp" {
  experiment_name = "actuarial-risk-modeling-${var.environment}-${random_string.pai_suffix.result}"
  workspace_id    = alicloud_pai_workspace_workspace.actuarial.id
  artifact_uri    = "oss://${alicloud_oss_bucket.training_data.bucket}/experiments/"
}

# Training run for Actuarial Risk Modeling (PAI DLC training job)
# Note: This is a placeholder; actual training job is submitted via PAI DLC.
# The alicloud_pai_workspace_run resource is not yet available in provider,
# so use CLI/console for actual training jobs or keep as placeholder.
resource "alicloud_pai_workspace_run" "actuarial_run" {
  count         = var.enable_training_jobs ? 1 : 0
  run_name      = "actuarial-training-${var.environment}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  experiment_id = alicloud_pai_workspace_experiment.actuarial_exp.id
  source_type   = "TrainingService"
  source_id     = "paidlc-${var.environment}"  # Placeholder for DLC job ID
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

# Model registration for Actuarial risk model
resource "alicloud_pai_workspace_model" "actuarial_model" {
  model_name     = "actuarial-risk-model-${var.environment}-${random_string.pai_suffix.result}"
  workspace_id   = alicloud_pai_workspace_workspace.actuarial.id
  accessibility  = "PRIVATE"
  model_type     = "Checkpoint"
  task           = "tabular-regression"
  domain         = "finance"
  model_doc      = "oss://${alicloud_pai_workspace_experiment.actuarial_exp.artifact_uri}/models/README.md"
  labels {
    key   = "framework"
    value = "pytorch"
  }
  labels {
    key   = "model-family"
    value = "qwen"
  }
}


data "alicloud_zones" "gpu" {
  available_instance_type = var.gpu_instance_type
  available_disk_category = "cloud_essd"
}

# Dedicated VPC for AI workloads with 3 segments
# Change from hardcoded 10.30.0.0/16 to variable
resource "alicloud_vpc" "ai" {
  vpc_name   = "${var.environment}-ai-vpc"
  cidr_block = var.ai_lab_vpc_cidr
  tags       = merge(var.tags, { Workload = "AI" })
}

# Update subnet CIDRs using cidrsubnet relative to the new /16
resource "alicloud_vswitch" "data" {
  vpc_id       = alicloud_vpc.ai.id
  cidr_block   = cidrsubnet(var.ai_lab_vpc_cidr, 8, 1)   # 10.2.1.0/24
  zone_id      = data.alicloud_zones.gpu.zones[0].id
  vswitch_name = "${var.environment}-ai-data"
  tags         = var.tags
}

resource "alicloud_vswitch" "training" {
  vpc_id       = alicloud_vpc.ai.id
  cidr_block   = cidrsubnet(var.ai_lab_vpc_cidr, 8, 2)   # 10.2.2.0/24 (RDMA ready)
  zone_id      = data.alicloud_zones.gpu.zones[0].id
  vswitch_name = "${var.environment}-ai-training-rdma"
  tags         = merge(var.tags, { Network = "RDMA" })
}

resource "alicloud_vswitch" "inference" {
  vpc_id       = alicloud_vpc.ai.id
  cidr_block   = cidrsubnet(var.ai_lab_vpc_cidr, 8, 3)   # 10.2.3.0/24
  zone_id      = data.alicloud_zones.gpu.zones[0].id
  vswitch_name = "${var.environment}-ai-inference"
  tags         = var.tags
}

# Workspace-level Resource Groups (Claims vs Actuarial isolation)
resource "alicloud_resource_manager_resource_group" "claims" {
  resource_group_name = "rg-ai-claims-${var.environment}"
  display_name        = "AI-Claims-${var.environment}"
}

resource "alicloud_resource_manager_resource_group" "actuarial" {
  resource_group_name = "rg-ai-actuarial-${var.environment}"
  display_name        = "AI-Actuarial-${var.environment}"
}

# ACK managed Kubernetes cluster for GPU training
resource "alicloud_cs_managed_kubernetes" "gpu" {
  name               = "${var.environment}-gpu-ack"
  vswitch_ids = [alicloud_vswitch.training.id]
  pod_cidr           = "172.20.0.0/16"
  service_cidr       = "172.21.0.0/20"
  new_nat_gateway    = false
  tags               = var.tags
}

# GPU node pool with auto-scaling (dynamic GPU allocation)
resource "alicloud_cs_kubernetes_node_pool" "gpu_pool" {
  cluster_id    = alicloud_cs_managed_kubernetes.gpu.id
  node_pool_name = "gpu-autoscale"
  vswitch_ids   = [alicloud_vswitch.training.id]
  instance_types = [var.gpu_instance_type]

  scaling_config {
    enable   = true
    min_size = 0
    max_size = var.gpu_max_nodes
  }
  system_disk_category = "cloud_essd"
  tags                 = merge(var.tags, { Network = "eRDMA" })
}

# Encrypted OSS for training datasets and model artifacts
resource "alicloud_oss_bucket" "training_data" {
  bucket = "ai-training-data-${var.environment}"
  tags   = merge(var.tags, { DataClass = "sensitive" })
}

resource "alicloud_oss_bucket_server_side_encryption" "training_enc" {
  bucket            = alicloud_oss_bucket.training_data.bucket
  sse_algorithm     = "KMS"
  kms_master_key_id = var.kms_key_id
}
