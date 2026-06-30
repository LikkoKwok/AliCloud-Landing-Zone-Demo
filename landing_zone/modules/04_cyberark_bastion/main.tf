# ============================================
# DATA SOURCES
# ============================================
data "alicloud_zones" "available" {
  available_resource_creation = "VSwitch"
}

# ============================================
# SHARED SERVICE VPC
# Contains: Unified Ingress SLB, CyberArk, Ops Bastion
# ============================================
resource "alicloud_vpc" "shared_service" {
  vpc_name   = "${var.environment}-shared-service-vpc"
  cidr_block = var.shared_service_vpc_cidr
  tags       = merge(var.tags, { Service = "shared-services" })

  # lifecycle {
  #   prevent_destroy = true
  # }
}

# Shared Service Subnets
resource "alicloud_vswitch" "unified_ingress" {
  vpc_id       = alicloud_vpc.shared_service.id
  cidr_block   = cidrsubnet(var.shared_service_vpc_cidr, 8, 1)
  zone_id      = data.alicloud_zones.available.zones[0].id
  vswitch_name = "${var.environment}-unified-ingress"
  tags         = merge(var.tags, { Tier = "ingress" })
}

resource "alicloud_vswitch" "ai_gateway" {
  vpc_id       = alicloud_vpc.shared_service.id
  cidr_block   = cidrsubnet(var.shared_service_vpc_cidr, 8, 10)
  zone_id      = data.alicloud_zones.available.zones[0].id
  vswitch_name = "${var.environment}-ai-gateway"
  tags         = merge(var.tags, { Tier = "ai-gateway" })
}

resource "alicloud_vswitch" "cyberark_pvwa" {
  vpc_id       = alicloud_vpc.shared_service.id
  cidr_block   = cidrsubnet(var.shared_service_vpc_cidr, 8, 20)
  zone_id      = data.alicloud_zones.available.zones[0].id
  vswitch_name = "${var.environment}-cyberark-pvwa"
  tags         = merge(var.tags, { Tier = "cyberark" })
}

resource "alicloud_vswitch" "cyberark_vault" {
  vpc_id       = alicloud_vpc.shared_service.id
  cidr_block   = cidrsubnet(var.shared_service_vpc_cidr, 8, 21)
  zone_id      = data.alicloud_zones.available.zones[0].id
  vswitch_name = "${var.environment}-cyberark-vault"
  tags         = merge(var.tags, { Tier = "cyberark" })
}

resource "alicloud_vswitch" "ops_bastion" {
  vpc_id       = alicloud_vpc.shared_service.id
  cidr_block   = cidrsubnet(var.shared_service_vpc_cidr, 8, 30)
  zone_id      = data.alicloud_zones.available.zones[0].id
  vswitch_name = "${var.environment}-ops-bastion"
  tags         = merge(var.tags, { Tier = "ops" })
}

# ============================================
# UNIFIED INGRESS SLB
# ============================================
# resource "alicloud_slb_load_balancer" "unified_ingress" {
#   load_balancer_name   = "${var.environment}-unified-ingress"
#   vswitch_id           = alicloud_vswitch.unified_ingress.id
#   load_balancer_spec   = "slb.s2.small"
#   address_type         = "intranet"
#   tags                 = var.tags
# }

# ============================================
# BASTION HOST (Jump server)
# ============================================
resource "alicloud_security_group" "bastion_sg" {
  vpc_id      = alicloud_vpc.shared_service.id
  security_group_name        = "${var.environment}-bastion-sg"
  description = "Security group for bastion host"
  tags        = merge(var.tags, { Service = "bastion" })
}

# Inbound: SSH from your public IP
resource "alicloud_security_group_rule" "bastion_ssh_from_me" {
  count             = var.my_public_ip != "" ? 1 : 0
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  security_group_id = alicloud_security_group.bastion_sg.id
  cidr_ip           = var.my_public_ip
  description       = "SSH from my public IP"
}

# Outbound: SSH to all internal VPCs (10.0.0.0/8)
resource "alicloud_security_group_rule" "bastion_to_internal" {
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  security_group_id = alicloud_security_group.bastion_sg.id
  cidr_ip           = "10.0.0.0/8"
  description       = "SSH to all internal VPCs"
}

# Outbound to 10.1.0.0/16
resource "alicloud_security_group_rule" "all_tcp_to_core_insurance" {
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "1/65535"
  security_group_id = alicloud_security_group.bastion_sg.id
  cidr_ip           = "10.1.0.0/16"
  description       = "All TCP to Core Insurance"
}


# Outbound: all internal VPCs (10.0.0.0/8)
resource "alicloud_security_group_rule" "https_to_internal" {
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.bastion_sg.id
  cidr_ip           = "10.0.0.0/8"
  description       = "Connect to all internal VPCs"
}

# Outbound: all internal VPCs (10.0.0.0/8)
resource "alicloud_security_group_rule" "http_to_internal" {
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.bastion_sg.id
  cidr_ip           = "10.0.0.0/8"
  description       = "Connect to all internal VPCs"
}

# ============================================
# CYBERARK INSTANCES
# ============================================

# PVWA Instance
resource "alicloud_instance" "cyberark_pvwa" {
  count                 = 0   # set to 1 for demo, 0 to save cost
  instance_name         = "${var.environment}-cyberark-pvwa"
  instance_type         = var.instance_type
  image_id              = var.image_id
  vswitch_id            = alicloud_vswitch.cyberark_pvwa.id
  security_groups       = [alicloud_security_group.cyberark_pvwa_sg.id]
  system_disk_category  = "cloud_essd"
  system_disk_encrypted = true
  tags                  = merge(var.tags, { Role = "CyberArk-PVWA", Mock = "true" })
}

# Vault Instance
resource "alicloud_instance" "cyberark_vault" {
  count                 = 0   # set to 1 for demo, 0 to save cost
  instance_name         = "${var.environment}-cyberark-vault"
  instance_type         = var.instance_type
  image_id              = var.image_id
  vswitch_id            = alicloud_vswitch.cyberark_vault.id
  security_groups       = [alicloud_security_group.cyberark_vault_sg.id]
  system_disk_category  = "cloud_essd"
  system_disk_encrypted = true
  tags                  = merge(var.tags, { Role = "CyberArk-Vault", Mock = "true" })
}

# Bastion ECS instance
resource "alicloud_instance" "bastion" {
  count           = 1   # set to 1 for demo, 0 to save cost
  instance_name   = "${var.environment}-bastion-host"
  instance_type   = var.instance_type
  image_id        = var.image_id
  vswitch_id      = alicloud_vswitch.ops_bastion.id
  security_groups = [alicloud_security_group.bastion_sg.id]

  # Bind a public IP
  internet_max_bandwidth_out = 5
  
  system_disk_category  = "cloud_essd"
  system_disk_encrypted = true
  
  tags = merge(var.tags, { 
    Service = "bastion-host",
    Role    = "management"
  })
}

# ============================================
# ATTACH SHARED SERVICE VPC TO CEN
# ============================================
resource "alicloud_cen_transit_router_vpc_attachment" "shared_service" {
  # count             = var.cen_id != "" ? 1 : 0    # count will affect terraform planning
  cen_id            = var.cen_id
  transit_router_id = var.transit_router_id
  vpc_id            = alicloud_vpc.shared_service.id
  auto_publish_route_enabled = true  # KEEPS ROUTE SYNCHRONIZATION ENABLED
  
  zone_mappings {
    zone_id    = data.alicloud_zones.available.zones[0].id
    vswitch_id = alicloud_vswitch.unified_ingress.id
  }
}