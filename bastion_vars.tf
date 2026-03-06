variable "bastion_key_name" {
  description = "Name of an existing AWS Key Pair to attach to the Bastion host for SSH access"
  type        = string
  default     = ""
}
