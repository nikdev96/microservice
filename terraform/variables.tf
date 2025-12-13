variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "machine_type" {
  description = "Machine type for the VM"
  type        = string
  default     = "e2-medium"  # 2 vCPU, 4GB RAM
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key for access to the VM"
  type        = string
  default     = ""
}
