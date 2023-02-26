variable "prefixname" {
  type = string
  description = "Prefix Name of Application"
}
variable "common_tags" {
  type = map
  description = "Common Tags for Resources"
  default = {}
}
variable "create_iam_resources" {
  type = bool
  description = "Boolean value for creating IAM resources on module(Set to false if you want to reuse this module in your account)"
  default = true
}
variable "security_group_rules" {
  # type = list(object({
  #   type = string
  #   port = number
  #   protocol = string
  #   cidr_blocks = list(string)
  #   security_group_id = string
  #   description = string
  # }))
    type = any
    description = "Security Group Rule to Attach to Default Cluster Security Group"
    default = []
  # EXAMPLE  
  # default = [
    
  #   {
  #       type = "ingress"
  #       port = "80"
  #       protocol = "tcp"
  #       cidr_blocks = ["172.31.0.0/16"]
  #       description =  "HTTP Access to VPC"
  #   },
  #   {
  #       type = "ingress"
  #       port = "22"
  #       protocol = "tcp"
  #       cidr_blocks = ["172.31.0.0/16"]
  #       description =  "SSH Access to VPC"
  #   }
  # ]
}
######################
#EKS CLUSTER VARIABLES
######################
variable "cluster_version" {
  type = string
  description = "Version of EKS Cluster"
  default = "1.24"
}
variable "eks_addons" {
  type = list(string)
  description = "Addons of cluster"
  default = ["coredns","kube-proxy","vpc-cni"]
}
#################################
#EKS CLUSTER NODE GROUP VARIABLES
#################################
variable "instance_types" {
  type = list(string)
  description = "Instance Types for Worker Nodes"
  default = [ "t3.medium" ]
}
variable "min_size" {
  type = number
  description = "Minimum number of nodes in EKS Cluster"
}
variable "desired_size" {
  type = number
  description = "Desired number of nodes in EKS Cluster"
}
variable "max_size" {
  type = number
  description = "Maximum number of nodes in EKS Cluster"
}
variable "ami_type" {
  type = string
  description = "AMI type for Nodes"
  default = "AL2_x86_64"
}
variable "disk_size" {
  type = number
  description = "Disk Size for Nodes"
  default = 20
}