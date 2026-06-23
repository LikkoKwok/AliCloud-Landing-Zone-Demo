output "ai_vpc_id"             { value = alicloud_vpc.ai.id }
output "ack_cluster_id"        { value = alicloud_cs_managed_kubernetes.gpu.id }
output "claims_rg_id"          { value = alicloud_resource_manager_resource_group.claims.id }
output "actuarial_rg_id"       { value = alicloud_resource_manager_resource_group.actuarial.id }
output "training_bucket"       { value = alicloud_oss_bucket.training_data.bucket }
output "inference_vswitch_id"  { value = alicloud_vswitch.inference.id }

output "claims_workspace_id" {
  value = alicloud_pai_workspace_workspace.claims.id
}

output "actuarial_workspace_id" {
  value = alicloud_pai_workspace_workspace.actuarial.id
}

output "claims_dataset_id" {
  value = alicloud_pai_workspace_dataset.claims_ocr_data.id
}

output "actuarial_dataset_id" {
  value = alicloud_pai_workspace_dataset.actuarial_data.id
}

output "claims_model_id" {
  value = alicloud_pai_workspace_model.claims_llm.id
}

output "actuarial_model_id" {
  value = alicloud_pai_workspace_model.actuarial_model.id
}

output "actuarial_experiment_id" {
  value = alicloud_pai_workspace_experiment.actuarial_exp.id
}