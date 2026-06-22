# ============================================
# ROUTE TABLES FOR EACH ENVIRONMENT WEB SUBNET
# Requirement: Force all outbound traffic through Palo Alto firewall
# ============================================

# SIT Route Table
resource "alicloud_route_table" "sit_web_rt" {
  vpc_id           = alicloud_vpc.core_insurance.id
  route_table_name = "${var.environment}-sit-web-rt"
  description      = "Forces SIT web traffic through Palo Alto"
}

resource "alicloud_route_entry" "sit_default_route" {
  count                = 1 # var.palo_alto_trust_eni_id != "" ? 1 : 0
  route_table_id       = alicloud_route_table.sit_web_rt.id
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type         = "NetworkInterface"
  nexthop_id           = var.palo_alto_trust_eni_id
  description          = "Force SIT outbound traffic through Palo Alto"
}

resource "alicloud_route_table_attachment" "sit_attach" {
  vswitch_id     = alicloud_vswitch.sit_web.id
  route_table_id = alicloud_route_table.sit_web_rt.id
}

# UAT Route Table
resource "alicloud_route_table" "uat_web_rt" {
  vpc_id           = alicloud_vpc.core_insurance.id
  route_table_name = "${var.environment}-uat-web-rt"
  description      = "Forces UAT web traffic through Palo Alto"
}

resource "alicloud_route_entry" "uat_default_route" {
  count                = 1 # var.palo_alto_trust_eni_id != "" ? 1 : 0
  route_table_id       = alicloud_route_table.uat_web_rt.id
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type         = "NetworkInterface"
  nexthop_id           = var.palo_alto_trust_eni_id
  description          = "Force UAT outbound traffic through Palo Alto"
}

resource "alicloud_route_table_attachment" "uat_attach" {
  vswitch_id     = alicloud_vswitch.uat_web.id
  route_table_id = alicloud_route_table.uat_web_rt.id
}

# PreProd Route Table
resource "alicloud_route_table" "preprod_web_rt" {
  vpc_id           = alicloud_vpc.core_insurance.id
  route_table_name = "${var.environment}-preprod-web-rt"
  description      = "Forces PreProd web traffic through Palo Alto"
}

resource "alicloud_route_entry" "preprod_default_route" {
  count                = 1 # var.palo_alto_trust_eni_id != "" ? 1 : 0
  route_table_id       = alicloud_route_table.preprod_web_rt.id
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type         = "NetworkInterface"
  nexthop_id           = var.palo_alto_trust_eni_id
  description          = "Force PreProd outbound traffic through Palo Alto"
}

resource "alicloud_route_table_attachment" "preprod_attach" {
  vswitch_id     = alicloud_vswitch.preprod_web.id
  route_table_id = alicloud_route_table.preprod_web_rt.id
}

# Prod Route Table
resource "alicloud_route_table" "prod_web_rt" {
  vpc_id           = alicloud_vpc.core_insurance.id
  route_table_name = "${var.environment}-prod-web-rt"
  description      = "Forces Prod web traffic through Palo Alto"
}

resource "alicloud_route_entry" "prod_default_route" {
  count                = 1 # var.palo_alto_trust_eni_id != "" ? 1 : 0
  route_table_id       = alicloud_route_table.prod_web_rt.id
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type         = "NetworkInterface"
  nexthop_id           = var.palo_alto_trust_eni_id
  description          = "Force Prod outbound traffic through Palo Alto"
}

resource "alicloud_route_table_attachment" "prod_attach" {
  vswitch_id     = alicloud_vswitch.prod_web.id
  route_table_id = alicloud_route_table.prod_web_rt.id
}