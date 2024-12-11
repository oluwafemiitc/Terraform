# Resource Group Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}


variable "location" {
  description = "Azure region"
  type        = string
}

# Network Variables
variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the subnet"
  type        = list(string)
}

# VM Variables
variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
}

variable "vm_size" {
  description = "Size of the VMs"
  type        = string
}

variable "admin_username" {
  description = "Administrator username"
  type        = string
}

variable "admin_password" {
  description = "Administrator password"
  type        = string
  sensitive   = true
}