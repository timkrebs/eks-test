# Vault Secrets Operator with Amazon EKS

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL%202.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0)
[![Terraform](https://img.shields.io/badge/Terraform-1.3+-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/eks/)
[![HashiCorp Vault](https://img.shields.io/badge/HashiCorp-Vault-000000?logo=vault&logoColor=white)](https://www.vaultproject.io/)

A complete, production-ready implementation of HashiCorp Vault Secrets Operator (VSO) with Amazon EKS that demonstrates secure, automated secret management in Kubernetes environments.

## 📖 Full Tutorial

**👉 [Read the complete step-by-step tutorial on Medium](https://medium.com/@your-username/vault-secrets-operator-eks-tutorial)**

This repository contains all the infrastructure code and configuration files referenced in the detailed Medium article that walks you through building a secure secrets management pipeline from scratch.

## 🎯 What You'll Build

This tutorial teaches you how to create a production-ready secrets management system that includes:

- **🏗️ Amazon EKS Cluster** - Managed Kubernetes with proper networking and security
- **🔐 HashiCorp Vault Integration** - Enterprise-grade secret management (HCP or self-hosted)
- **🔄 Automated Secret Sync** - Real-time synchronization from Vault to Kubernetes
- **🛡️ Production Security** - Proper RBAC, service accounts, and network policies
- **🔄 Live Secret Rotation** - Automatic updates without application downtime
- **📱 Application Integration** - Demo app showing secret consumption patterns

## 🏛️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HashiCorp     │    │    Vault       │    │   Kubernetes    │
│     Vault       │◄──►│   Secrets      │◄──►│   Applications  │
│  (HCP/Self-hosted)│    │   Operator     │    │   (Demo App)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         └──────────────►│   Amazon EKS    │◄─────────────┘
                        │    Cluster      │
                        └─────────────────┘
```

## 🗂️ Repository Structure

```
vault-secrets-operator-eks/
├── 📁 terraform/                    # Infrastructure as Code
│   ├── main.tf                     # EKS cluster and VPC configuration
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Cluster connection details
│   └── terraform.tf                # Provider requirements
├── 📁 kubernetes/                  # Kubernetes manifests (created during tutorial)
│   ├── vault-connection.yaml       # Vault connection configuration
│   ├── vault-auth.yaml            # Authentication setup
│   ├── vault-static-secrets.yaml  # Secret synchronization rules
│   └── demo-app.yaml              # Example application
├── 📁 vault/                      # Vault configuration (created during tutorial)
│   └── policies/
│       └── vso-policy.hcl         # Vault access policy
├── .gitignore                      # Terraform and sensitive files
├── LICENSE                         # Mozilla Public License 2.0
└── README.md                       # This file
```

## 🚀 Quick Start

### Prerequisites

Ensure you have these tools installed:

- [Terraform](https://www.terraform.io/downloads) (>= 1.3)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- [Vault CLI](https://www.vaultproject.io/downloads)
- Access to HashiCorp Vault (HCP Vault Dedicated, Vault Enterprise, or Vault OSS)

### 1. Deploy Infrastructure

```bash
# Clone this repository
git clone https://github.com/your-username/vault-secrets-operator-eks.git
cd vault-secrets-operator-eks

# Navigate to terraform directory
cd terraform/

# Initialize and deploy
terraform init
terraform plan
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region us-east-2 --name $(terraform output -raw cluster_name)
```

### 2. Follow the Complete Tutorial

**The Terraform configuration in this repo is just the foundation!** 

👉 **[Continue with the full tutorial on Medium](https://medium.com/@your-username/vault-secrets-operator-eks-tutorial)** to learn how to:

- Configure Vault authentication and policies
- Install and configure the Vault Secrets Operator
- Set up secure service account authentication
- Create and sync secrets from Vault to Kubernetes
- Deploy applications that consume the secrets
- Test automatic secret rotation
- Implement production security best practices

## 🧪 What You'll Learn

### Core Concepts
- **Kubernetes Authentication with Vault** - How VSO authenticates across namespaces
- **Service Account Strategy** - Why you need multiple service accounts and how to configure them
- **RBAC Permissions** - Essential cluster roles for token validation
- **Secret Synchronization** - Real-time sync patterns and refresh intervals

### Production Patterns
- **Namespace Isolation** - Proper resource organization and security boundaries
- **Secret Transformation** - Converting Vault secrets into application-specific formats
- **Automatic Restarts** - Ensuring applications pick up secret changes
- **Monitoring & Alerting** - Observability for secret synchronization failures

### Security Best Practices
- **Least Privilege Access** - Granular Vault policies per application
- **Token Lifecycle Management** - Short-lived tokens and automatic rotation
- **Network Security** - NetworkPolicies for VSO communications
- **Audit Logging** - Comprehensive secret access tracking

## 🛠️ Infrastructure Details

This Terraform configuration creates:

### Amazon EKS Cluster
- **Version**: 1.29 (latest stable)
- **Node Groups**: 2 managed groups with auto-scaling
- **Instance Types**: t3.small (cost-optimized for tutorials)
- **Networking**: VPC with public/private subnets across 3 AZs

### VPC Configuration
- **CIDR**: 10.0.0.0/16
- **Public Subnets**: 10.0.4.0/24, 10.0.5.0/24, 10.0.6.0/24
- **Private Subnets**: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
- **NAT Gateway**: Single gateway for cost optimization
- **ELB Ready**: Proper subnet tagging for load balancers

### Cluster Add-ons
- **EBS CSI Driver**: For persistent volume support
- **IRSA**: IAM Roles for Service Accounts integration
- **Public API**: Accessible from internet (can be restricted in production)

## 🔍 Troubleshooting

The tutorial includes comprehensive troubleshooting for common issues:

- **VaultConnection Not Found** - Namespace isolation problems
- **Service Account Not Authorized** - Vault role configuration issues  
- **Permission Denied** - Missing RBAC permissions for token validation
- **Secrets Not Syncing** - Authentication and policy debugging

## 📊 Expected Costs

Running this tutorial will incur AWS costs:

- **EKS Cluster**: ~$0.10/hour for control plane
- **EC2 Instances**: ~$0.0464/hour for 3 × t3.small instances
- **NAT Gateway**: ~$0.045/hour
- **EBS Volumes**: ~$0.10/GB/month

**Estimated total**: ~$4-5/day while running

> 💡 **Tip**: Run `terraform destroy` when you're done to avoid ongoing charges!

## 🤝 Contributing

Found an issue or want to improve the tutorial? Contributions are welcome!

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -am 'Add improvement'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Create a Pull Request

## 📚 Additional Resources

- [HashiCorp Vault Secrets Operator Documentation](https://developer.hashicorp.com/vault/docs/platform/k8s/vso)
- [Amazon EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [HashiCorp Vault Documentation](https://developer.hashicorp.com/vault/docs)

## 📄 License

This project is licensed under the Mozilla Public License 2.0 - see the [LICENSE](LICENSE) file for details.

## ⭐ Support

If this tutorial helped you, please:
- ⭐ Star this repository
- 📖 Share the [Medium article](https://medium.com/@your-username/vault-secrets-operator-eks-tutorial)
- 🐦 Follow me on [Twitter](https://twitter.com/your-username) for more DevOps content

---

**🎯 Ready to master Kubernetes secrets management?**  
**👉 [Start with the complete tutorial on Medium](https://medium.com/@your-username/vault-secrets-operator-eks-tutorial)**
