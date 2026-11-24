data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_ecrpublic_authorization_token" "karpenter" {
  # Public ECR authorization is only issued from us-east-1.
  region = "us-east-1"
}

locals {
  # EKS requires control-plane subnets in two availability zones.
  # Every node stays in the first zone so pod traffic does not cross AZs.
  azs              = slice(data.aws_availability_zones.available.names, 0, 2)
  workload_subnets = [module.vpc.public_subnets[0]]

  # vpc-cni and kube-proxy are DaemonSets. operator Exists lets them run on
  # the monitoring taint and the GPU taint. Their upstream defaults already
  # do this; setting it here keeps that guarantee in this configuration.
  daemonset_tolerations = jsonencode({
    tolerations = [
      {
        operator = "Exists"
      }
    ]
  })
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.8.0"

  name = var.cluster_name
  cidr = "10.0.0.0/16"
  azs  = local.azs

  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_ec2_tag" "karpenter_discovery" {
  resource_id = module.vpc.public_subnets[0]
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.30.2"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  enable_cluster_creator_admin_permissions = true
  endpoint_public_access                   = true
  deletion_protection                      = false

  # Empty disables control-plane logs. The module default would turn them on.
  enabled_log_types = []

  upgrade_policy = {
    support_type = "STANDARD"
  }

  # Stay on the standard control plane. Do not select a provisioned tier.
  control_plane_scaling_config = {
    tier = "standard"
  }

  addons = {
    coredns = {
      configuration_values = jsonencode({
        nodeSelector = {
          workload = "system"
        }
      })
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {
      configuration_values = local.daemonset_tolerations
    }
    vpc-cni = {
      before_compute       = true
      configuration_values = local.daemonset_tolerations
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = local.workload_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    system = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      min_size       = 0
      max_size       = 1
      desired_size   = var.node_count
      subnet_ids     = local.workload_subnets

      labels = {
        workload = "system"
      }
    }

    monitoring = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      min_size       = 0
      max_size       = 1
      desired_size   = var.node_count
      subnet_ids     = local.workload_subnets

      labels = {
        workload = "monitoring"
      }

      taints = {
        monitoring = {
          key    = "workload"
          value  = "monitoring"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.30.2"

  cluster_name = module.eks.cluster_name

  namespace       = "kube-system"
  service_account = "karpenter"

  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = var.cluster_name
  create_pod_identity_association = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "helm_release" "karpenter" {
  namespace           = "kube-system"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.karpenter.user_name
  repository_password = data.aws_ecrpublic_authorization_token.karpenter.password
  chart               = "karpenter"
  version             = "1.12.1"
  wait                = true
  timeout             = 600

  values = [
    <<-EOT
    replicas: 1
    dnsPolicy: Default
    nodeSelector:
      workload: system
    serviceAccount:
      create: true
      name: karpenter
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    resources:
      requests:
        cpu: 50m
        memory: 128Mi
      limits:
        memory: 256Mi
    EOT
  ]

  depends_on = [module.eks]
}

resource "helm_release" "nvidia_device_plugin" {
  name             = "nvidia-device-plugin"
  repository       = "https://nvidia.github.io/k8s-device-plugin"
  chart            = "nvidia-device-plugin"
  version          = "0.20.2"
  namespace        = "nvidia-device-plugin"
  create_namespace = true
  wait             = true
  timeout          = 600

  # Default affinity already selects nvidia.com/gpu.present=true, which the
  # GPU NodePool sets. NFD and GFD stay off. The chart tolerates the GPU taint.
  values = [
    <<-EOT
    gfd:
      enabled: false
    nfd:
      enabled: false
    EOT
  ]

  depends_on = [module.eks]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.19.0"
  namespace        = "argocd"
  create_namespace = true
  wait             = true
  timeout          = 900

  values = [
    <<-EOT
    global:
      nodeSelector:
        workload: system
    dex:
      enabled: false
    applicationSet:
      enabled: false
    notifications:
      enabled: false
    configs:
      params:
        server.insecure: true
    server:
      service:
        type: ClusterIP
      resources:
        requests:
          cpu: 50m
          memory: 64Mi
        limits:
          memory: 256Mi
    controller:
      resources:
        requests:
          cpu: 50m
          memory: 256Mi
        limits:
          memory: 512Mi
    repoServer:
      resources:
        requests:
          cpu: 50m
          memory: 128Mi
        limits:
          memory: 256Mi
    redis:
      resources:
        requests:
          cpu: 50m
          memory: 64Mi
        limits:
          memory: 128Mi
    EOT
  ]

  depends_on = [module.eks]
}

resource "helm_release" "argocd_apps" {
  name       = "demo-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.9"
  namespace  = "argocd"
  wait       = true
  timeout    = 600

  values = [
    yamlencode({
      applications = {
        demo = {
          namespace = "argocd"
          project   = "default"
          source = {
            repoURL        = var.gitops_repo_url
            targetRevision = var.gitops_target_revision
            path           = "cluster"
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "argocd"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=true",
              "ServerSideApply=true",
            ]
          }
        }
        monitoring = {
          namespace = "argocd"
          project   = "default"
          sources = [
            {
              repoURL        = "https://prometheus-community.github.io/helm-charts"
              chart          = "kube-prometheus-stack"
              targetRevision = "93.9.0"
              helm = {
                valueFiles = ["$values/cluster/monitoring-values.yaml"]
              }
            },
            {
              repoURL        = var.gitops_repo_url
              targetRevision = var.gitops_target_revision
              ref            = "values"
            },
          ]
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "monitoring"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = [
              "CreateNamespace=true",
              "ServerSideApply=true",
            ]
          }
        }
      }
    })
  ]

  depends_on = [helm_release.argocd]
}

resource "aws_ecr_repository" "debugger_agent" {
  name                 = "debugger-agent"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_budgets_budget" "demo" {
  count = var.budget_email == "" ? 0 : 1

  name         = var.cluster_name
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_email]
  }
}
