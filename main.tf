# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.region
}

# Filter out local zones, which are not currently supported 
# with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "education-eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "education-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}

# EBS CSI Driver setup
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

# HCP Vault Dedicated Configuration
resource "hcp_vault_cluster" "main" {
  cluster_id      = "vault-cluster-${random_string.suffix.result}"
  hvn_id          = hcp_hvn.main.hvn_id
  tier            = var.vault_tier
  public_endpoint = true
}

# HCP HVN (HashiCorp Virtual Network)
resource "hcp_hvn" "main" {
  hvn_id         = "main-hvn-${random_string.suffix.result}"
  cloud_provider = "aws"
  region         = var.region
  cidr_block     = "172.25.16.0/20"
}

# HVN Route to VPC
resource "hcp_hvn_route" "main" {
  hvn_link         = hcp_hvn.main.self_link
  hvn_route_id     = "main-hvn-route-${random_string.suffix.result}"
  destination_cidr = "10.0.0.0/16"
  target_link      = hcp_aws_network_peering.peer.self_link
}

# AWS Network Peering
resource "hcp_aws_network_peering" "peer" {
  hvn_id          = hcp_hvn.main.hvn_id
  peering_id      = "peer-${random_string.suffix.result}"
  peer_vpc_id     = module.vpc.vpc_id
  peer_account_id = data.aws_caller_identity.current.account_id
  peer_vpc_region = var.region
}

# Accept the VPC peering connection
resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
  auto_accept               = true

  tags = {
    Name = "HCP peering (${hcp_aws_network_peering.peer.peering_id})"
  }
}

# Route table entries for peering connection
resource "aws_route" "private_subnets_to_hvn" {
  count                     = length(module.vpc.private_route_table_ids)
  route_table_id            = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block    = hcp_hvn.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id
}

resource "aws_route" "public_subnets_to_hvn" {
  count                     = length(module.vpc.public_route_table_ids)
  route_table_id            = module.vpc.public_route_table_ids[count.index]
  destination_cidr_block    = hcp_hvn.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id
}

# Data source for AWS caller identity
data "aws_caller_identity" "current" {}

# Vault Admin Token for initial setup
resource "hcp_vault_cluster_admin_token" "main" {
  cluster_id = hcp_vault_cluster.main.cluster_id
}

# IAM role for Vault Secrets Operator
resource "aws_iam_role" "vault_secrets_operator" {
  name = "vault-secrets-operator-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:vault-secrets-operator-system:vault-secrets-operator-controller-manager"
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}