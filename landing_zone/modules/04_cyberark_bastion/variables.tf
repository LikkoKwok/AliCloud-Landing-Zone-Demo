variable "environment" {
  description = "Environment name (e.g., demo, prod)"
  type        = string
}

variable "shared_service_vpc_cidr" {
  description = "CIDR block for Shared Service VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "region" {
  description = "Alibaba Cloud region"
  type        = string
  default     = "cn-hongkong"
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

variable "my_public_ip" {
  description = "Mock whitelist IP"
  type        = string
}

variable "instance_type" {
  description = "ECS instance type for bastion host, CyberArk PVWA, and CyberArk Vault"
  type        = string
  default     = "ecs.e-c1m1.large"
}

variable "image_id" {
  description = "Image ID for CyberArk and bastion instances"
  type        = string
  default     = "aliyun_3_x64_20G_alibase_20240528.vhd"
}

variable "hub_vpc_id" {
  description = "Hub Security VPC ID for CEN attachment"
  type        = string
}

variable "cen_id" {
  description = "CEN instance ID for VPC attachment"
  type        = string
}

variable "transit_router_id" {
  description = "CEN Transit Router ID"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
