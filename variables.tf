variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-private-eks"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "node_instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_ami_type" {
  description = "AMI type for the EKS node group"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_custom_ami" {
  description = "Custom AMI ID for EKS nodes. If set, it overrides node_ami_type."
  type        = string
  default     = ""
}

variable "node_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 3
}

variable "bastion_instance_type" {
  description = "Instance type for the Bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_ami" {
  description = "AMI ID for the Bastion host"
  type        = string
  default     = "" # Left empty to use dynamic AL2 data source if not provided
}
