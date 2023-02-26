### AUTHOR --- DITMIR SPAHIU ###
################################

###################
#DATA
###################
data "aws_subnets" "subnets" {
  filter {
    name = "tag:Name"
    values = ["*Internal*"]
  }
}

data "aws_iam_role" "eks_cluster_role" {
  count = var.create_iam_resources ? 0 : 1
  name = "eks-cluster-role"
}

data "aws_iam_role" "eks_node_role" {
  count = var.create_iam_resources ? 0 : 1
  name = "eks-node-role"
}

data "aws_eks_addon_version" "addon_version" {
  count = length(var.eks_addons)
  addon_name = var.eks_addons[count.index]
  kubernetes_version = aws_eks_cluster.eks-cluster.version
  most_recent = true
}

####################
#CLUSTER
####################

resource "aws_iam_role" "cluster_role" {
  count = var.create_iam_resources ? 1 : 0
  name = "eks-cluster-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "EKSClusterPolicy" {
  count = var.create_iam_resources ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.cluster_role[count.index].name
}

resource "aws_iam_role_policy_attachment" "EKSServicePolicy" {
  count = var.create_iam_resources ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = aws_iam_role.cluster_role[count.index].name  
}

resource "aws_eks_cluster" "eks-cluster" {
  name = join("-", [var.prefixname, "cluster"])
  version = var.cluster_version
  role_arn = var.create_iam_resources ? aws_iam_role.cluster_role[0].arn : data.aws_iam_role.eks_cluster_role[0].arn

  vpc_config {
    subnet_ids = data.aws_subnets.subnets.ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  depends_on = [
    aws_iam_role_policy_attachment.EKSClusterPolicy,
    aws_iam_role_policy_attachment.EKSServicePolicy
  ]

  tags = var.common_tags
}

resource "aws_security_group_rule" "name" {
  security_group_id = aws_eks_cluster.eks-cluster.vpc_config[0].cluster_security_group_id
  count = length(var.security_group_rules)
  type = var.security_group_rules[count.index].type
  from_port = var.security_group_rules[count.index].port
  to_port = var.security_group_rules[count.index].port
  protocol = var.security_group_rules[count.index].protocol
  cidr_blocks = try(var.security_group_rules[count.index].cidr_blocks,null)
  source_security_group_id = try(var.security_group_rules[count.index].security_group_id,null)
  description = var.security_group_rules[count.index].description
}

resource "aws_eks_addon" "addon" {
  count = length(var.eks_addons)
  cluster_name         = aws_eks_cluster.eks-cluster.name
  addon_name           = var.eks_addons[count.index]
  addon_version = data.aws_eks_addon_version.addon_version[count.index].version
  tags = var.common_tags
  depends_on = [
    data.aws_eks_addon_version.addon_version,
    aws_eks_node_group.eks-node-group
  ]
  resolve_conflicts = "OVERWRITE"
}

resource "aws_ec2_tag" "cluster-sg-tagname" {
  resource_id = aws_eks_cluster.eks-cluster.vpc_config[0].cluster_security_group_id
  key         = "Name"
  value       = join("-", [var.prefixname, "cluster-sg"])
}

resource "aws_ec2_tag" "cluster-sg-tags" {
    for_each = { for k, v in var.common_tags :
    k => v if k != "Name" &&  v != null
  }

  resource_id = aws_eks_cluster.eks-cluster.vpc_config[0].cluster_security_group_id
  key         = each.key
  value       = each.value
}

####################
#WORKER NODES
####################

resource "aws_iam_role" "node-role" {
  count = var.create_iam_resources ? 1 : 0
  name = "eks-node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "EKSWorkerNodePolicy" {
  count = var.create_iam_resources ? 1 : 0  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node-role[count.index].name
}

resource "aws_iam_role_policy_attachment" "EKS_CNI_Policy" {
  count = var.create_iam_resources ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node-role[count.index].name
}

resource "aws_iam_role_policy_attachment" "EC2ContainerRegistryReadOnly" {
  count = var.create_iam_resources ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node-role[count.index].name
}

resource "aws_launch_template" "node-group-template" {
  name = join("-", [var.prefixname, "node-template"])

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size             = var.disk_size
      delete_on_termination   = "true"           
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
    Name = join("-", [var.prefixname, "cluster-node"]),
  })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.common_tags, {
    Name = join("-", [var.prefixname, "cluster-node-volume"]),
  })
  }
  tags = var.common_tags
}

resource "aws_eks_node_group" "eks-node-group" {
  cluster_name = aws_eks_cluster.eks-cluster.name
  node_group_name = join("-", [var.prefixname, "node-group"])
  node_role_arn = var.create_iam_resources ? aws_iam_role.node-role[0].arn : data.aws_iam_role.eks_node_role[0].arn
  subnet_ids = data.aws_subnets.subnets.ids
  ami_type = var.ami_type
  instance_types = var.instance_types

  launch_template {
    id      = aws_launch_template.node-group-template.id
    version = aws_launch_template.node-group-template.latest_version
  }

  scaling_config {
    min_size = var.min_size
    desired_size = var.desired_size
    max_size = var.max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.EKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.EKS_CNI_Policy,
    aws_iam_role_policy_attachment.EC2ContainerRegistryReadOnly
  ] 

  tags = var.common_tags
}