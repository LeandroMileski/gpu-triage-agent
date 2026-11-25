variable "region" {
  description = "AWS region for the demo cluster."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name. The Karpenter manifests hardcode the default, so change those too if you change this."
  type        = string
  default     = "k8s-debug-demo"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Must stay inside standard support. Do not use 1.34: its standard support ends on 2 December 2026."
  type        = string
  default     = "1.36"
}

variable "node_count" {
  description = "Desired size of the system and monitoring node groups. Set to 0 to pause the cluster and keep only the control plane."
  type        = number
  default     = 1
}

variable "gitops_repo_url" {
  description = "Git repository Argo CD syncs. A public repository needs no credentials."
  type        = string
  default     = "https://github.com/LeandroMileski/gpu-triage-agent.git"
}

variable "gitops_target_revision" {
  description = "Git revision Argo CD tracks."
  type        = string
  default     = "HEAD"
}

variable "monthly_budget_usd" {
  description = "Account-wide monthly budget that emails when a forgotten cluster is still billing."
  type        = number
  default     = 50
}

variable "budget_email" {
  description = "Address for the budget alarm. The budget is skipped when this is empty."
  type        = string
  default     = ""
}
