variable "name" {
  type        = string
  description = "Nom de la VM."
}

variable "region" {
  type        = string
  description = "Région."
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "Région invalide."
  }
}

variable "plan" {
  type        = string
  default     = "small"
  description = "Plan instance VM (nano/micro/small/medium/large/xlarge)."
}

variable "template" {
  type        = string
  default     = "ubuntu-24.04"
  description = "Template QEMU (clé catalogue ou UUID custom)."
}

variable "vnet_id" {
  type = string
}

variable "ssh_key_ids" {
  type    = list(string)
  default = []
}

variable "user_data" {
  type    = string
  default = null
}

variable "public_ip_id" {
  type    = string
  default = null
}

variable "root_password" {
  type      = string
  default   = null
  sensitive = true
}

variable "tags" {
  type    = list(string)
  default = []
}
