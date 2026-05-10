variable "name" {
  description = "Human-readable name (1–100 chars). Used as base for the slug."
  type        = string
  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 100
    error_message = "name must be 1 to 100 characters."
  }
}

variable "region" {
  description = "Region code (RNN, PAR, ABJ). Forces replacement."
  type        = string
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "region must be one of RNN, PAR, ABJ."
  }
}

variable "expose_public" {
  description = "Expose the registry on the public Internet (DNS public IONOS → public Gateway IP)."
  type        = bool
  default     = false
}

variable "expose_private" {
  description = "Expose the registry on the CETIC private LAN (DNS interne split-horizon → private Gateway IP)."
  type        = bool
  default     = true
}

variable "image_tag" {
  description = "Tag of the upstream `registry` image. Use `null` to follow the backoffice-managed default (currently 2.8)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Free-form tags (max 60, max 50 chars each)."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.tags) <= 60
    error_message = "tags can hold at most 60 entries."
  }
  validation {
    condition     = alltrue([for t in var.tags : length(t) <= 50])
    error_message = "each tag must be at most 50 characters."
  }
}
