output "hub_vpc_id" {
  value = alicloud_vpc.hub.id
}

output "hub_vpc_cidr" {
  value = alicloud_vpc.hub.cidr_block
}

output "trust_subnet_cidr" {
  value = alicloud_vswitch.trusted.cidr_block
}

output "untrust_subnet_cidr" {
  value = alicloud_vswitch.untrusted.cidr_block
}

output "ops_subnet_cidr" {
  value = alicloud_vswitch.ops.cidr_block
}

output "cen_id" {
  value = var.cen_id
}

output "transit_router_id" {
  value = var.transit_router_id
}

output "palo_alto_trust_eni_id" {
  value = data.alicloud_network_interfaces.palo_alto_eni.ids[0]
}

output "palo_alto_instance_ids" {
  value = alicloud_instance.palo_alto[*].id
}

output "kms_key_id" {
  description = "The ID of the KMS key used for encryption"
  value       = ""
  # value       = alicloud_kms_key.hub.id
}

output "hub_vpc_attachment_id" {
  value = alicloud_cen_transit_router_vpc_attachment.hub.id
}