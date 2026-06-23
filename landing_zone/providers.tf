# no need to provide ID for default master ac, it is authorized by access_key and secret_key
provider "alicloud" {
  alias  = "master"
  region = var.region
}

provider "alicloud" {
  alias  = "singapore"
  region = var.secondary_region
}

provider "alicloud" {
  alias  = "hub"
  region = var.region
  # in production, need to enable services individually in related ac besides master ac
  # assume_role {
  #   role_arn = "acs:ram::${var.account_ids.hub_security}:role/ResourceDirectoryAccountAccessRole"
  # }
}

provider "alicloud" {
  alias  = "shared"
  region = var.region
  # in production, need to enable services individually in related ac besides master ac
  # assume_role {
  #   role_arn = "acs:ram::${var.account_ids.shared_service}:role/ResourceDirectoryAccountAccessRole"
  # }
}

provider "alicloud" {
  alias  = "log"
  region = var.region
  # in production, need to enable services individually in related ac besides master ac
  # assume_role {
  #   role_arn = "acs:ram::${var.account_ids.log}:role/ResourceDirectoryAccountAccessRole"
  # }
}

provider "alicloud" {
  alias  = "app"
  region = var.region
  # in production, need to enable services individually in related ac besides master ac
  # assume_role {
  #   role_arn = "acs:ram::${var.account_ids.app}:role/ResourceDirectoryAccountAccessRole"
  # }
}

provider "alicloud" {
  alias  = "ai_training"
  region = var.region
  # in production, need to enable services individually in related ac besides master ac
  # assume_role {
  #   role_arn = "acs:ram::${var.account_ids.ai_training}:role/ResourceDirectoryAccountAccessRole"
  # }
}

provider "alicloud" {
  alias  = "ai_inference"
  region = var.region
  # in production, need to enable services individually in related ac besides master ac
  # assume_role {
  #   role_arn = "acs:ram::${var.account_ids.ai_inference}:role/ResourceDirectoryAccountAccessRole"
  # }
}