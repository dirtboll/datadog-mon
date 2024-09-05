terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.22.0"
    }
  }
}

# Provide your own aws auth mechanism
# e.g. via AWS_DEFAULT_PROFILE environment variable
provider "aws" {
  profile = "datadog"
}

data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_availability_zones" "current" {
  state = "available"
}

data "aws_region" "current" {}

provider "kubernetes" {
  host                   = aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.default.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.default.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.default.token
  }
}

provider "postgresql" {
  host            = aws_db_instance.default.address
  port            = aws_db_instance.default.port
  database        = "postgres"
  username        = aws_db_instance.default.username
  password        = aws_db_instance.default.password
  sslmode         = "require"
  connect_timeout = 16
  superuser       = false
}
