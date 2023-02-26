# eks-module

## Authors
- [Ditmir Spahiu](https://code.rbi.tech/IALASPD)
## RESOURCES

This module will create the following resources:


1-IAM Role for Cluster 


2-IAM Role for Node Group 


3-Security Group Additional Rules for Cluster Default Security Group

4-Launch Template for EKS Node Group

5-EKS Cluster


6-EKS Managed Node Group


## Variables used in this module


| Variable | Description|Type|Default|Required|
|----------|------------|----|-------|--------|
|prefixname|Prefix Name of Application|string|empty|Yes|
|common_tags|Common Tags for resources|map|empty|No|
|create_iam_resources|Boolean value for creating IAM resources on module|boolean|true|Should be false if you have used the module in your AWS Account|
|security_group_rules|Additional Security Group Rules for Cluster|list(map(string))|null|No|
|cluster_version|Version of EKS Cluster|string|1.24|No|
|eks_addons|Addons of cluster|list(string)|["coredns","kube-proxy","vpc-cni"]|No|
|instance_types|Instance Types for Node Group|list(string)|[t3.medium]|No|
|min_size|Minimum number of nodes in EKS Cluster|number|empty|Yes|
|desired_size|Desired number of nodes in EKS Cluster|number|empty|Yes|
|max_size|Maximum number of nodes in EKS Cluster|number|empty|Yes|
|ami_type|AMI type for Nodes|string|AL2_x86_64|No|
|disk_size|Disk Size for Nodes|number|20|No|


## How to use it

### Example with Only Required Variables:
```
module "eks"  {

  source = "git@code.rbi.tech:IALASPD/eks.git"

  prefixname = "MyApp"

  min_size = 2

  desired_size = 2

  max_size = 2

}
```
### Example with ALL Variables:
```
module "eks" {

  source = "git@code.rbi.tech:IALASPD/eks.git"

  cluster_version="1.24"

  prefixname = "MyApp"

  create_iam_resources = true #default
  
  eks_addons = ["vpc-cni","coredns","kube-proxy","aws-ebs-csi-driver"]

  common_tags = {

    "Billing-Tag" = "Billing"

    "App-Tag" = "My-APP"

  }

  instance_types=["c5.large"]
  
  ami_type = "AL2_x86_64"

  disk_size = 20

  min_size = 2

  desired_size = 3

  max_size = 4

  security_group_rules = [

    {

        type = "ingress"

        port = "80"

        protocol = "tcp"

        cidr_blocks = ["172.31.0.0/16"]

        description =  "HTTP Access to VPC"

    },

    {

        type = "ingress"

        port = "22"

        protocol = "tcp"

        cidr_blocks = ["172.31.0.0/16"]

        description =  "SSH Access to VPC"

    }

  ]

}
```
### Note
If you already has used this module in your account and want to use it again,you should declare variable **create_iam_resources** to false so the module will use the previous IAM resources
