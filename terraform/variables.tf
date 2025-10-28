variable "admin_username" {
  type        = string
  description = "The username for the local account that will be created on the new VM"
  default = "adminuser"
}

variable "resource_group_name_prefix" {
  type        = string
  description = "Prefix for the resource group name"
  default     = "whanos"
}

variable "resource_group_location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "France Central"
}

variable "vm_size" {
  description = "Virtual machine size"
  type        = string
  default     = "Standard_B2s"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/whanos_key.pub"
}
