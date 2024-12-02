variable "resource_group_name" {
  description = "The name of the existing Resource Group."
  type        = string
}

variable "project_name" {
  description = "The project name for resource naming."
  type        = string
}

variable "vm_size" {
  description = "The size of the virtual machine."
  type        = string
  default     = "Standard_B1s"
}

variable "os_publisher" {
  description = "The publisher of the OS image."
  type        = string
  default     = "Canonical"
}

variable "os_offer" {
  description = "The offer of the OS image."
  type        = string
  default     = "UbuntuServer"
}

variable "os_sku" {
  description = "The SKU of the OS image."
  type        = string
  default     = "18.04-LTS"
}

variable "admin_username" {
  description = "The admin username for the VM."
  type        = string
}

variable "admin_password" {
  description = "The admin password for the VM."
  type        = string
  sensitive   = true
}
