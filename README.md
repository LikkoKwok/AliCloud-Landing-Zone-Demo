# Alibaba Cloud Landing Zone Exam - Infrastructure Summary
This summary serves to explain how my architecture can map with Alibaba Cloud Landing Zone 
Partner Certification Exam by addressing the specific requirements.

## 1. Organization, Accounts, and Resource Isolation
## Requirements
- Resources within each deployment environment (SIT, UAT, pre-production, production) must be fully isolated
- Personnel permissions must be isolated across environments
- Clean separation between traditional insurance business and AI workloads
- Project-level workspace isolation for AI teams (Claims vs Actuarial)
- GPU resource quotas and scheduling policies

## How My Architecture Addresses This
Requirement	Implementation Environment Isolation	4 separate subnets per environment (SIT, UAT, PreProd, Prod) within Core Insurance VPC, each with dedicated CIDR blocks and Security Groups Business Separation	Dedicated VPCs for Core Insurance (10.1.0.0/16) and AI Lab (10.2.0.0/16) AI Team Isolation	PAI Workspaces created for Claims and Actuarial teams with separate Resource Groups and Datasets Network Isolation	Cross-environment blocking rules in Security Groups prevent SIT/UAT/PreProd from accessing Prod resources GPU Quotas	ACK GPU node pool with auto-scaling (min_size=0, max_size=var.gpu_max_nodes) ensures dynamic GPU allocation

## 2. Identity and Access Management
## Requirements
- Azure AD integration for SSO (single sign-on)
- Least privilege principle for all roles
- API key governance (per-application, rotated every 90 days)
- Service roles with temporary credentials (no long-lived access keys)

## How My Architecture Addresses This
Requirement	Implementation
Azure AD SSO	SAML federation with Azure AD via alicloud_ram_saml_provider
RBAC Roles	Comprehensive role definitions including cloud-admin, network-admin, dba, ai-platform-admin, ml-engineer, data-scientist, model-reviewer, ai-user, ai-auditor
Federated Roles	Each role maps to a RAM role with sts:AssumeRole policy for Azure AD users
Least Privilege	Each role has scoped system policies (e.g., AliyunPAIReadOnlyAccess for model reviewers, AliyunVPCFullAccess for network admins)
API Key Governance	Per-application service role ai-claims-app-invoke with temporary credentials; API keys stored in self-managed KMS

## 3. Financial Management
## Requirements
- Cost breakdown by business application and business line
- Granular cost attribution for GPU compute, training time, inference API calls, token consumption
- Resource groups and tags as primary cost attribution mechanism
- Proactive budget alerts and hard spending caps

## How My Architecture Addresses This
Requirement	Implementation
Cost Attribution	Resource Groups per business line (claims, actuarial, customer-service, shared)
Tagging Strategy	Comprehensive tagging including Environment, ManagedBy, Project, Team, Service, Tier
GPU Cost Tracking	Separate PAI Workspaces with independent Resource Groups for Claims and Actuarial teams
AI-Specific Costs	OSS buckets tagged with DataClass (raw-pii, masked) for storage cost attribution
Budget Enforcement	alicloud_bss_business_budget with 80% and 100% alert thresholds; auto-pause logic referenced in MLOps pipeline

## 4. Network Architecture
## Requirements
- Unified network ingress and egress centrally managed by Cloud Management Team
- Network isolation across environments
- RDMA-capable infrastructure for GPU training
- Inference endpoints not exposed directly to internet
- TLS 1.2+ encryption for all cross-site data transfers

## How My Architecture Addresses This
Requirement	Implementation
Hub and Spoke Design	Hub Security VPC (10.20.0.0/16) with Palo Alto firewall connecting to all spoke VPCs via CEN Transit Router
Unified Ingress	Internal SLB in Shared Service VPC (10.10.1.0/24) as single entry point for all traffic
Environment Isolation	Separate subnets per environment with Security Group rules preventing cross-environment access
RDMA-Ready Training	AI Lab VPC with dedicated training subnet (10.2.2.0/24) supporting eRDMA
Inference Protection	Inference subnet (10.2.3.0/24) with Security Groups allowing only AI Gateway (10.10.1.0/24) access
Secure Cross-Site Connectivity	CEN Transit Router with encrypted transit between Hong Kong and Singapore
Management Plane Isolation	Ops Bastion (10.10.30.0/24) as single management entry point, integrated with CyberArk
Force Traffic through Firewall	Route tables with 0.0.0.0/0 pointing to Palo Alto ENI for outbound traffic; gateway route tables for inbound traffic inspection

## 5. Security Architecture
## Requirements
- Existing security products used where available (Palo Alto, CyberArk, KMS)
- Cloud-native products for gaps (vulnerability management, antivirus)
- North-south traffic protection with firewall-first principle
- Automated detection of encryption gaps
- Automated PII classification and masking pipeline
- LLM guardrails (prompt injection prevention, content moderation)
- Pod security policies and network policies for GPU Kubernetes clusters

## How My Architecture Addresses This
Requirement	Implementation
Palo Alto Firewall	Mock Palo Alto instances (for demo) with untrusted/trusted interfaces; production ready for actual Palo Alto VM-Series deployment
CyberArk Integration	Dedicated CyberArk PVWA and Vault instances with separate subnets and Security Group rules (port 1858 for Vault communication)
KMS Encryption	Central KMS key for encrypting all OSS buckets, RDS instances, and disk volumes
Encryption Monitoring	Cloud Config rules (ecs-disk-encrypted, oss-bucket-server-side-encryption-enabled, rds-tde-enabled)
PII Data Pipeline	DataWorks project pii_masking_demo orchestrating PII scanning and redaction from raw_zone to curated_zone
LLM Guardrails	OSS bucket for guardrail policies, RAM role for guardrail service, and defense-in-depth approach (retrieval-time inspection, input validation, output screening)
Container Scanning	ACR configuration with vulnerability scanning (Trivy) for all AI training and inference images
Network Policies	ACK cluster with Terway network policies enabled; explicit deny rules between training and inference pods
Explicit Deny Rules	All resources have Deny rules for direct internet access (priority 100), enforcing traffic through Palo Alto

## 6. Compliance and Audit
## Requirements
- Multi-jurisdictional compliance (HK IA, MAS TRM, PDPO, PDPA, PCI-DSS)
- Centralized audit logs retained for 3 years
- Multi-account compliance governance with preventive controls
- AI-specific compliance rules (GPU access, training data handling, model deployment approval)
- Model registry with versioning and approval gates

## How My Architecture Addresses This
Requirement	Implementation
Centralized Logging	SLS Project central-audit-demo with 3-year retention (1095 days) for all cloud operations and AI platform logs
ActionTrail Integration	Multi-account ActionTrail delivering ALL API calls to SLS, including AI platform operations
Compliance Rules	Config rules for unencrypted disk, OSS encryption, RDS encryption, SLB HTTPS
AI Compliance	Specific Config rule ai-inference-no-public-ip ensuring inference endpoints are not exposed
Preventive Controls	Control Policies (deny-logstore-deletion, deny-actiontrail-stop) applied at root folder level
Model Registry	OSS bucket with versioning and KMS encryption for model artifacts; model-reviewer approval gate for production promotion
AI Audit Trail	Dedicated SLS logstore ai-operations capturing every model training run, inference API call, and model version deployment
Compliance Dashboard	Cloud Config aggregator providing unified view of compliance posture across all accounts and AI workloads

## 7. Operations and Observability
## Requirements
- Centralized log collection for all log types
- Full-stack observability for AI services (request → gateway → inference → GPU)
- Key metrics: inference latency, token consumption, GPU utilization, error rates
- AIOps for root cause analysis and proactive alerting
- Cost-to-value dashboard correlating business metrics against AI infrastructure cost

## How My Architecture Addresses This
Requirement	Implementation
Centralized Logging	SLS project central-audit-demo with dedicated logstores for cloud operations and AI operations
AI Full-Stack Observability	Logstore ai-fullstack-trace with indexed fields for inference latency, tokens, GPU utilization, error rates, and queue depth
AIOps Integration	CloudMonitor alerts for GPU health and model drift; SLS Copilot for natural-language root cause analysis
Cost-to-Value Dashboard	SLS dashboard ai-cost-to-value correlating business metrics (claims per hour, inquiries resolved) against AI infrastructure cost
Proactive Alerting	CMS alarm contact group aiops-oncall for proactive alerting on model drift and data quality issues

## 8. Automation
## Requirements
- Everything defined as code with Terraform
- IaC modules covering VPCs, security groups, K8s clusters, AI workspaces, platform configurations
- Automated MLOps pipeline for full ML lifecycle
- All stages reproducible and version-controlled

## How My Architecture Addresses This
Requirement	Implementation
100% Terraform	All infrastructure provisioned via Terraform - no manual console operations
Modular Design	12+ modules including master_account, identity_sso, hub_security, cyberark_bastion, core_insurance_app, pai_platform, ai_data_security, ai_guardrails, financial_governance, logging_account, model_governance, observability
Multi-Account Support	Provider configuration with assume_role for 7 separate accounts (hub, shared, log, app, ai_training, ai_inference, master)
AI Infrastructure	PAI Workspaces, Datasets, Experiments, and Models all provisioned via Terraform
CI/CD Ready	Variables, outputs, and backend configuration (OSS remote state) for automated deployments
Version Control	Complete Git repository with semantic versioning and documented release process

## Architecture Diagram Summary
![architecture](architecture.jpg)


## Summary of Key Design Decisions
- Multi-Account Strategy: 7 dedicated accounts for Hub Security, Shared Service, Logging, Core Insurance, AI Training, AI Inference, and Master Account - ensuring complete isolation and cost attribution
- Hub and Spoke Network: All VPCs connected via CEN Transit Router with Palo Alto as central inspection point for north-south traffic
- AI Workspace Isolation: PAI Workspaces with separate Resource Groups and GPU quotas for Claims and Actuarial teams
- Comprehensive RBAC: 9 distinct roles mapped to Azure AD groups with least-privilege policies
- Full Observability: Centralized SLS logging with 3-year retention, AI-specific metrics, and cost-to-value dashboard
- IaC-First Approach: 100% Terraform with modular design, remote state, and CI/CD readiness
- Compliance by Design: Multi-jurisdictional compliance (HK IA, MAS TRM, PDPO, PDPA, PCI-DSS) with automated Config rules and Control Policies

***

# Useful commands:
## To update state with the existing architecture on cloud:
terraform refresh -var-file="environments/demo.tfvars"

## Last Resort:
Delete state file in OSS:
aliyun oss rm oss://oss-alicloud-sso-demo-tfstate-01/landing-zone/state/terraform.tfstate

Clean local state:
run clean_apply.sh

## apply modules one by one to figure out bottleneck:

terraform apply -target=module.hub_security -var-file="environments/demo.tfvars"
terraform apply -target=module.shared_service -var-file="environments/demo.tfvars"
terraform apply -target=module.core_insurance_app -var-file="environments/demo.tfvars"

terraform apply -target=module.pai_platform -var-file="environments/demo.tfvars"
terraform apply -target=module.logging_account -var-file="environments/demo.tfvars"
terraform apply -target=module.ai_data_security -var-file="environments/demo.tfvars"
terraform destroy -var-file="environments/demo.tfvars"

## terraform destroy but ignore CEN and TR:
terraform destroy -var-file="environments/demo.tfvars" \
  -exclude=module.hub_security.data.alicloud_cen_instances.existing \
  -exclude=module.hub_security.alicloud_cen_transit_router_vpc_attachment.hub

## Manual delete from state file unwanted resources created by a specific module
terraform state list
terraform state rm module.<your_module_name>