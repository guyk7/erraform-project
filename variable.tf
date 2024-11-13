variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string
  default     = "ron"
}

variable "admin_username" {
  description = "Admin username for the VMs"
  type        = string
  default     = "ron"
}

variable "ssh_public_key" {
  description = "The SSH public key for accessing VMs"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "westus2"  # Set to region with necessary SKU availability
}

variable "vm_size" {
  description = "The size of the VMs"
  type        = string
  default     = "Standard_A1_v2"
}
variable "client_id" {
  type        = string
  description = "Client ID for Azure authentication"
}

variable "client_secret" {
  type        = string
  description = "Client Secret for Azure authentication"
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "Tenant ID for Azure authentication"
}

variable "subscription_id" {
  type        = string
  description = "Subscription ID for Azure authentication"
}