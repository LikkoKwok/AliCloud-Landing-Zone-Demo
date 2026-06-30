region                  = "cn-hongkong"
secondary_region        = "ap-southeast-1"
environment             = "demo"

# VPC CIDR
hub_vpc_cidr            = "10.20.0.0/16"
core_insurance_vpc_cidr = "10.1.0.0/16"
ai_lab_vpc_cidr         = "10.2.0.0/16"
shared_service_vpc_cidr = "10.10.0.0/16"

# Restricted Compute Resources for Demo Purpose
az_count                = 1
enable_gpu_cluster      = true # change to true to provision PAI GPU cluster
firewall_instance_type  = "ecs.e-c1m1.large"
bastion_instance_type   = "ecs.e-c1m1.large"


# Log
log_retention_days      = 30

# switch PAI region for available gpu resource
pai_region = "cn-hongkong"
# pai_region = "ap-southeast-1"  # singapore
# pai_region = "cn-shenzhen"     

# CEN
cen_id = "cen-ycdypx620qa3zhdfo7"
transit_router_id = "tr-j6cuc0gmwpgt0vyh1ihzs"

# Admin
my_public_ip =  "47.89.101.4/32"   #"223.255.178.182/32"
