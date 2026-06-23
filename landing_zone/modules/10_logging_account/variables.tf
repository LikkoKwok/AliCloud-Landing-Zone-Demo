variable "environment"        { type = string }
variable "region"             { type = string }
variable "account_id" {
  description = "Account ID for logging"
  type        = string
}

variable "log_retention_days" { 
    type = number
    default = 30 
    }

variable "tags"               { 
    type = map(string)
    default = {} 
    }
