variable "environment" {
  description = "Environment name (e.g., demo, sit, uat, preprod, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "DEPRECATED: Use core_insurance_vpc_cidr instead"
  type        = string
  default     = null
}

variable "core_insurance_vpc_cidr" {
  description = "CIDR block for Core Insurance VPC. Must be /16 to accommodate 4 environments"
  type        = string
  default     = "10.1.0.0/16"
  
  validation {
    condition     = can(regex("^10\\.([0-9]{1,3})\\.0\\.0/16$", var.core_insurance_vpc_cidr))
    error_message = "CIDR must be a /16 block in 10.x.0.0/16 format (e.g., 10.1.0.0/16)"
  }
}


variable "transit_router_id" {
  description = "CEN Transit Router ID for VPC attachment"
  type        = string
}

variable "cen_id" {
  description = "CEN instance ID"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption at rest"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class for SQL Server"
  type        = string
  default     = "rds.mssql.s2.large" # need to make sure db tier is available in HK region
}

variable "db_storage_gb" {
  description = "Database storage in GB"
  type        = number
  default     = 50
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "palo_alto_trust_eni_id" {
  description = "ENI ID of Palo Alto's Trust interface for traffic inspection"
  type        = string
  default     = ""
}

variable "management_vpc_cidr" {
  description = "CIDR block for Management VPC (bastion host network)"
  type        = string
  default     = "10.100.0.0/16"
}

variable "my_public_ip" {
  description = "Your public IP for SSH access to bastion host (e.g., '203.0.113.50/32')"
  type        = string
  default     = ""
}

variable "hub_attachment_id" {
  description = "Transit Router attachment ID of the Hub Security VPC"
  type        = string
}

# validate CIDR is /16
locals {
  effective_cidr = var.core_insurance_vpc_cidr != "" ? var.core_insurance_vpc_cidr : var.vpc_cidr
}