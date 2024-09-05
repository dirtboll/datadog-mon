locals {
  cluster_name   = "default"
}

## IAM

data "aws_iam_policy_document" "eks_cluster_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [ "eks.amazonaws.com" ]
    }
    actions = [ "sts:AssumeRole" ]
  }
}

data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [ "ec2.amazonaws.com" ]
    }
    actions = [ "sts:AssumeRole" ]
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "EKSClusterRole"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role_policy.json
  managed_policy_arns = [ 
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ]
}

resource "aws_iam_role" "eks_nodes_role" {
  name = "EKSNodeRole"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role_policy.json
  managed_policy_arns = [ 
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", 
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" 
  ]
}

resource "aws_iam_instance_profile" "eks_nodes_role" {
  name = "eks-node-role"
  role = aws_iam_role.eks_nodes_role.name
}



## EKS

resource "aws_eks_cluster" "default" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
    endpoint_public_access  = true
    security_group_ids = data.aws_security_groups.default.ids
  }
  access_config {
    authentication_mode = "API"
  }
}

data "tls_certificate" "default_cluster" {
  url = aws_eks_cluster.default.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "default_cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.default_cluster.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.default_cluster.url
}

data "aws_eks_cluster_auth" "default" {
  name = aws_eks_cluster.default.name
}



## Nodes

data "aws_ssm_parameter" "eks_bottlerocket_release_image" {
  name = "/aws/service/bottlerocket/aws-k8s-${aws_eks_cluster.default.version}/x86_64/latest/image_id"
}

resource "aws_launch_template" "default" {
  name = "default"
  block_device_mappings {
    device_name = "/dev/xvdb"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }
  vpc_security_group_ids = data.aws_security_groups.default.ids
  image_id = nonsensitive(data.aws_ssm_parameter.eks_bottlerocket_release_image.value)
  user_data = base64encode(
    <<-EOT
      [settings.kubernetes]
      "cluster-name" = "${local.cluster_name}"
      "api-server" = "${aws_eks_cluster.default.endpoint}"
      "cluster-certificate" = "${aws_eks_cluster.default.certificate_authority[0].data}"
      "cluster-dns-ip" = "${cidrhost(aws_eks_cluster.default.kubernetes_network_config[0].service_ipv4_cidr, 10)}"
      "max-pods" = 20
      [settings.kubernetes.node-labels]
      "eks.amazonaws.com/nodegroup-image" = "${nonsensitive(data.aws_ssm_parameter.eks_bottlerocket_release_image.value)}"
      "eks.amazonaws.com/capacityType" = "ON_DEMAND"
      "eks.amazonaws.com/nodegroup" = "default"
      [settings.kubernetes.kube-reserved]
      cpu = "10m"
      memory = "64Mi"
      ephemeral-storage = "1Gi"
      [settings.kubernetes.system-reserved]
      cpu = "10m"
      memory = "64Mi"
      ephemeral-storage = "1Gi"
    EOT
  )
}

resource "aws_eks_node_group" "default" {
  cluster_name  = aws_eks_cluster.default.name
  node_role_arn = aws_iam_role.eks_nodes_role.arn
  subnet_ids = data.aws_subnets.default.ids

  launch_template {
    name    = aws_launch_template.default.name
    version = aws_launch_template.default.latest_version
  }

  scaling_config {
    min_size     = 1
    max_size     = 2
    desired_size = 1
  }

  node_group_name = "default"
  instance_types  = ["t3.small"]
  capacity_type = "ON_DEMAND"

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size,
    ]
  }
}



## API Access

resource "aws_eks_access_entry" "caller" {
  cluster_name = aws_eks_cluster.default.name
  principal_arn = data.aws_iam_session_context.current.issuer_arn
}

resource "aws_eks_access_policy_association" "caller" {
  cluster_name = aws_eks_cluster.default.name
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_iam_session_context.current.issuer_arn
  access_scope {
    type       = "cluster"
  }
  depends_on = [aws_eks_access_entry.caller]
}
