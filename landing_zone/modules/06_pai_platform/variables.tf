variable "environment"      { type = string }
variable "gpu_instance_type" { type = string }
variable "vpc_cidr"          { type = string }
variable "kms_key_id"        { type = string }
variable "gpu_max_nodes"     { 
    type = number
    default = 4 
    }

variable "tags"              { 
    type = map(string)
    default = {} 
    }

variable "ai_lab_vpc_cidr" {
  description = "CIDR block for AI Lab VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "hub_vpc_id" {
  description = "Hub Security VPC ID for AI Gateway placement (shared with Palo Alto)"
  type        = string
}

variable "enable_training_jobs" {
  description = "Enable PAI training jobs (DLC runs) - set to false for cost saving"
  type        = bool
  default     = false
}