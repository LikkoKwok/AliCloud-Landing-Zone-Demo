terraform {
  required_providers {
    alicloud = {
      source = "aliyun/alicloud"
      version = ">= 1.241.0"  # Required for PAI workspace resources
    }
  }
}