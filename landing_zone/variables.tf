# ============================================
# REGION CONFIGURATION
# ============================================
variable "region" {
  description = "Primary Alibaba Cloud region"
  type        = string
  default     = "cn-hongkong"
}

variable "secondary_region" {
  description = "Secondary region for HK<->SG backbone"
  type        = string
  default     = "ap-southeast-1"
}

# ============================================
# ENVIRONMENT CONFIGURATION
# ============================================
variable "environment" {
  description = "Deployment environment: demo, sit, uat, preprod, prod"
  type        = string
}

# ============================================
# VPC CIDR CONFIGURATION
# ============================================
variable "hub_vpc_cidr" {
  description = "CIDR for Hub Security VPC (Palo Alto, WAF)"
  type        = string
  default     = "10.20.0.0/16"
}

variable "core_insurance_vpc_cidr" {
  description = "CIDR for Core Insurance VPC (4 environments)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "ai_lab_vpc_cidr" {
  description = "CIDR for AI Lab VPC (training + inference)"
  type        = string
  default     = "10.2.0.0/16"
}

variable "shared_service_vpc_cidr" {
  description = "CIDR for Shared Service VPC (ingress, CyberArk, bastion)"
  type        = string
  default     = "10.10.0.0/16"
}

# ============================================
# ACCOUNT IDS (for assume_role)
# ============================================
variable "account_ids" {
  type = map(string)
  default = {
    shared_service = "5947182043430388"
    hub_security   = "5204482043670830"
    log            = "5512782043745792"
    app            = "5641082043830083"
    ai_inference   = "5025582043875056"
    ai_training    = "5977182043911351"
  }
}

# ============================================
# COMPUTE CONFIGURATION
# ============================================
variable "az_count" {
  description = "Number of availability zones to span"
  type        = number
  default     = 2
}

variable "firewall_instance_type" {
  type    = string
  default = "ecs.g6.large"
}

variable "bastion_instance_type" {
  type    = string
  default = "ecs.g6.large"
}

variable "backbone_bandwidth_mbps" {
  type    = number
  default = 2
}

# ============================================
# AUTHENTICATION CONFIGURATION
# ============================================
variable "azure_ad_metadata_url" {
  type    = string
  default = ""
}

# ============================================
# SECURITY CONFIGURATION
# ============================================
# assume 10.100.0.0/16 as the internal network for admin access to CyberArk and bastion host
# variable "management_vpc_cidr" {
#   description = "CIDR block allowed to access CyberArk PVWA (HTTPS) and SSH"
#   type        = string
#   default     = "10.100.0.0/16"
# }

# ============================================
# LOGGING CONFIGURATION
# ============================================
variable "log_retention_days" {
  type    = number
  default = 1095  # comply with 3 years retention of cloud operation logs for audit requirement
}

# ============================================
# TAGS
# ============================================
variable "common_tags" {
  type    = map(string)
  default = {}
}


# ============================================
# CEN & TRANSIT ROUTER
# ============================================
variable "cen_id" {
  description = "Existing CEN instance ID (manually created)"
  type        = string
  default     = "cen-ycdypx620qa3zhdfo7"
}

variable "transit_router_id" {
  description = "Existing Transit Router ID"
  type        = string
  default     = "tr-j6cuc0gmwpgt0vyh1ihzs"
}

# Uncomment if using web server private IP for demo purposes
# output "mock_web_server_private_ip" {
#   value = module.core_insurance_app.mock_web_server_private_ip
# }

# PAI Related
variable "enable_gpu_cluster" {
  description = "Toggle GPU/AI training workloads"
  type        = bool
  default     = false
}

variable "enable_dsw_instance" {
  description = "Enable PAI DSW instance for demo"
  type        = bool
  default     = false
}

variable "gpu_instance_type" {
  description = "GPU instance type"
  type        = string
  default     = "ecs.gn6i-c4g1.xlarge"
}

variable "my_public_ip" {
  description = "Mock Whitelist IP for Admin SSH to bastion host and End users to Apps"
  type        = string
}