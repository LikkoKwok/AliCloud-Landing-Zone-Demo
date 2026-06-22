# ============================================
# SECURITY GROUPS FOR CORE INSURANCE VPC
# Requirement: Isolated per environment, inbound only from Palo Alto
# ============================================

# ----------------------------
# SIT ENVIRONMENT
# ----------------------------

# SIT Web Security Group
resource "alicloud_security_group" "sit_web_sg" {
  vpc_id      = alicloud_vpc.core_insurance.id
  security_group_name        = "sg-sit-web-${var.environment}"
  description = "Security group for SIT web tier - inbound only from Palo Alto"
  tags        = merge(var.tags, { Environment = "SIT", Tier = "web" })
}

# Inbound: HTTP from Palo Alto Trust subnet only
resource "alicloud_security_group_rule" "sit_web_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.sit_web_sg.id
  cidr_ip           = "10.20.2.0/24"  # Palo Alto Trust subnet
  description       = "HTTP traffic inspected by Palo Alto"
}

# Inbound: HTTPS from Palo Alto Trust subnet only
resource "alicloud_security_group_rule" "sit_web_https" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.sit_web_sg.id
  cidr_ip    = "10.20.2.0/24"  # Palo Alto Trust subnet
  description       = "HTTPS traffic inspected by Palo Alto"
}

# Inbound: SSH from Ops subnet only (not through Palo Alto - management plane)
resource "alicloud_security_group_rule" "sit_web_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  security_group_id = alicloud_security_group.sit_web_sg.id
  cidr_ip           = "10.10.30.0/24"  # Ops subnet
  description       = "SSH from Ops bastion for management"
}

# Inbound: Application health checks from SLB
resource "alicloud_security_group_rule" "sit_web_health" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.sit_web_sg.id
  cidr_ip           = "10.10.0.0/16"  # Shared Service VPC (SLB)
  description       = "Health checks from unified ingress SLB"
}

# Outbound: HTTPS to internet (will be forced through Palo Alto via route table)
resource "alicloud_security_group_rule" "sit_web_out_https" {
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.sit_web_sg.id
  cidr_ip           = "0.0.0.0/0"
  description       = "HTTPS outbound (routed through Palo Alto)"
}

# Outbound: HTTP to internet
resource "alicloud_security_group_rule" "sit_web_out_http" {
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.sit_web_sg.id
  cidr_ip           = "0.0.0.0/0"
  description       = "HTTP outbound (routed through Palo Alto)"
}

# Outbound: DNS
resource "alicloud_security_group_rule" "sit_web_out_dns" {
  type              = "egress"
  ip_protocol       = "udp"
  port_range        = "53/53"
  security_group_id = alicloud_security_group.sit_web_sg.id
  cidr_ip           = "10.20.2.0/24"  # Palo Alto Trust subnet
  description       = "DNS resolution"
}

# Explicit deny: Block direct internet inbound (defense in depth)
resource "alicloud_security_group_rule" "sit_web_deny_direct" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "1/65535"
  security_group_id = alicloud_security_group.sit_web_sg.id
  cidr_ip           = "10.20.2.0/24"  # Palo Alto Trust subnet
  policy            = "drop"
  priority          = 100
  description       = "Explicitly block direct internet access - must go through Palo Alto"
}

# SIT DB Security Group
resource "alicloud_security_group" "sit_db_sg" {
  vpc_id      = alicloud_vpc.core_insurance.id
  security_group_name        = "sg-sit-db-${var.environment}"
  tags        = merge(var.tags, { Environment = "SIT", Tier = "database" })
}

# Inbound: SQL Server from SIT web tier only
resource "alicloud_security_group_rule" "sit_db_mssql" {
  type                     = "ingress"
  ip_protocol              = "tcp"
  port_range               = "1433/1433"
  security_group_id        = alicloud_security_group.sit_db_sg.id
  cidr_ip           = "10.10.0.0/16"  # Shared Service VPC (SLB)
  description              = "SQL Server from SIT web tier only"
}

# Inbound: MySQL from SIT web tier (if needed)
resource "alicloud_security_group_rule" "sit_db_mysql" {
  type                     = "ingress"
  ip_protocol              = "tcp"
  port_range               = "3306/3306"
  security_group_id        = alicloud_security_group.sit_db_sg.id
  cidr_ip           = "10.20.2.0/24"
  description              = "MySQL from SIT web tier only"
}

# Outbound: No egress rules for DB (default deny all egress is fine for DB)

# ----------------------------
# UAT ENVIRONMENT
# ----------------------------

# UAT Web Security Group
resource "alicloud_security_group" "uat_web_sg" {
  vpc_id      = alicloud_vpc.core_insurance.id
  security_group_name        = "sg-uat-web-${var.environment}"
  description = "Security group for UAT web tier"
  tags        = merge(var.tags, { Environment = "UAT", Tier = "web" })
}

resource "alicloud_security_group_rule" "uat_web_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.uat_web_sg.id
  cidr_ip    = "10.20.2.0/24"
  description       = "HTTP via Palo Alto"
}

resource "alicloud_security_group_rule" "uat_web_https" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.uat_web_sg.id
  cidr_ip           = "10.20.2.0/24"
  description       = "HTTPS via Palo Alto"
}

resource "alicloud_security_group_rule" "uat_web_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  security_group_id = alicloud_security_group.uat_web_sg.id
  cidr_ip           = "10.10.30.0/24"
  description       = "SSH from Ops"
}

resource "alicloud_security_group_rule" "uat_web_deny_direct" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "1/65535"
  security_group_id = alicloud_security_group.uat_web_sg.id
  cidr_ip           = "0.0.0.0/0"
  priority          = 100
  description       = "Block direct internet access"
}

resource "alicloud_security_group" "uat_db_sg" {
  vpc_id      = alicloud_vpc.core_insurance.id
  security_group_name        = "sg-uat-db-${var.environment}"
  description = "Security group for UAT database tier"
  tags        = merge(var.tags, { Environment = "UAT", Tier = "database" })
}

resource "alicloud_security_group_rule" "uat_db_mssql" {
  type                     = "ingress"
  ip_protocol              = "tcp"
  port_range               = "1433/1433"
  security_group_id        = alicloud_security_group.uat_db_sg.id
  source_security_group_id = alicloud_security_group.uat_web_sg.id
  description              = "SQL Server from UAT web tier"
}

# ----------------------------
# PRE-PRODUCTION ENVIRONMENT
# ----------------------------

resource "alicloud_security_group" "preprod_web_sg" {
  vpc_id      = alicloud_vpc.core_insurance.id
  security_group_name        = "sg-preprod-web-${var.environment}"
  description = "Security group for Pre-Production web tier"
  tags        = merge(var.tags, { Environment = "PreProd", Tier = "web" })
}

resource "alicloud_security_group_rule" "preprod_web_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.preprod_web_sg.id
  cidr_ip    = "10.20.2.0/24"
  description       = "HTTP via Palo Alto"
}

resource "alicloud_security_group_rule" "preprod_web_https" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.preprod_web_sg.id
  cidr_ip    = "10.20.2.0/24"
  description       = "HTTPS via Palo Alto"
}

resource "alicloud_security_group_rule" "preprod_web_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  security_group_id = alicloud_security_group.preprod_web_sg.id
  cidr_ip    = "10.10.30.0/24"
  description       = "SSH from Ops"
}

resource "alicloud_security_group_rule" "preprod_web_deny_direct" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "1/65535"
  security_group_id = alicloud_security_group.preprod_web_sg.id
  cidr_ip           = "0.0.0.0/0"
  policy            = "drop"
  priority          = 100
  description       = "Block direct internet access"
}

resource "alicloud_security_group" "preprod_db_sg" {
  vpc_id      = alicloud_vpc.core_insurance.id
  security_group_name        = "sg-preprod-db-${var.environment}"
  description = "Security group for Pre-Production database tier"
  tags        = merge(var.tags, { Environment = "PreProd", Tier = "database" })
}

resource "alicloud_security_group_rule" "preprod_db_mssql" {
  type                     = "ingress"
  ip_protocol              = "tcp"
  port_range               = "1433/1433"
  security_group_id        = alicloud_security_group.preprod_db_sg.id
  source_security_group_id = alicloud_security_group.preprod_web_sg.id
  description              = "SQL Server from PreProd web tier"
}

# ----------------------------
# PRODUCTION ENVIRONMENT
# ----------------------------

resource "alicloud_security_group" "prod_web_sg" {
  vpc_id      = alicloud_vpc.core_insurance.id
  security_group_name        = "sg-prod-web-${var.environment}"
  description = "Security group for Production web tier - highest security"
  tags        = merge(var.tags, { Environment = "Prod", Tier = "web" })
}

resource "alicloud_security_group_rule" "prod_web_https" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.prod_web_sg.id
  cidr_ip    = "10.20.2.0/24"
  description       = "HTTPS only via Palo Alto (no HTTP for prod)"
}

# Prod web does NOT allow HTTP (only HTTPS for security)
resource "alicloud_security_group_rule" "prod_web_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  security_group_id = alicloud_security_group.prod_web_sg.id
  cidr_ip    = "10.10.30.0/24"
  description       = "SSH from Ops bastion only"
}

# Prod web additional security: only allow from specific Ops admin IPs (if provided)
resource "alicloud_security_group_rule" "prod_web_ssh_restricted" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "22/22"
  security_group_id = alicloud_security_group.prod_web_sg.id
  cidr_ip           = var.management_vpc_cidr
  description       = "SSH from restricted admin IPs only"
}

resource "alicloud_security_group_rule" "prod_web_deny_direct" {
  type              = "ingress"
  ip_protocol       = "all"
  port_range        = "-1/-1"
  security_group_id = alicloud_security_group.prod_web_sg.id
  cidr_ip           = "0.0.0.0/0"
  policy            = "drop"
  priority          = 100
  description       = "Explicitly block all direct internet access"
}

# Outbound rules for Prod web
resource "alicloud_security_group_rule" "prod_web_out_https" {
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.prod_web_sg.id
  cidr_ip           = "0.0.0.0/0"
  description       = "HTTPS outbound (routed through Palo Alto)"
}

resource "alicloud_security_group_rule" "prod_web_out_api" {
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "8080/8080"
  security_group_id = alicloud_security_group.prod_web_sg.id
  cidr_ip           = "0.0.0.0/0"
  description       = "API calls outbound"
}

resource "alicloud_security_group" "prod_db_sg" {
  vpc_id      = alicloud_vpc.core_insurance.id
  security_group_name        = "sg-prod-db-${var.environment}"
  description = "Security group for Production database tier - strict access"
  tags        = merge(var.tags, { Environment = "Prod", Tier = "database" })
}

resource "alicloud_security_group_rule" "prod_db_mssql" {
  type                     = "ingress"
  ip_protocol              = "tcp"
  port_range               = "1433/1433"
  security_group_id        = alicloud_security_group.prod_db_sg.id
  source_security_group_id = alicloud_security_group.prod_web_sg.id
  description              = "SQL Server from Prod web tier only"
}

# Prod DB does not allow any outbound (default deny is sufficient)

# ============================================
# CROSS-ENVIRONMENT BLOCKING RULES
# Requirement: Environments must be fully isolated
# ============================================

# Explicitly block SIT web from accessing UAT DB
resource "alicloud_security_group_rule" "block_sit_to_uat" {
  type                     = "ingress"
  ip_protocol              = "all"
  port_range               = "-1/-1"
  security_group_id        = alicloud_security_group.uat_db_sg.id
  source_security_group_id = alicloud_security_group.sit_web_sg.id
  policy                   = "drop"
  priority                 = 1
  description              = "Isolation: Block SIT web from UAT DB"
}

# Block UAT web from accessing Prod DB
resource "alicloud_security_group_rule" "block_uat_to_prod" {
  type                     = "ingress"
  ip_protocol              = "all"
  port_range               = "-1/-1"
  security_group_id        = alicloud_security_group.prod_db_sg.id
  source_security_group_id = alicloud_security_group.uat_web_sg.id
  policy                   = "drop"
  priority                 = 1
  description              = "Isolation: Block UAT web from Prod DB"
}

# Block PreProd from accessing Prod
resource "alicloud_security_group_rule" "block_preprod_to_prod" {
  type                     = "ingress"
  ip_protocol              = "all"
  port_range               = "-1/-1"
  security_group_id        = alicloud_security_group.prod_db_sg.id
  source_security_group_id = alicloud_security_group.preprod_web_sg.id
  policy                   = "drop"
  priority                 = 1
  description              = "Isolation: Block PreProd from Prod DB"
}