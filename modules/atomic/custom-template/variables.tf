variable "name" {
  type        = string
  description = "Nom du template custom (visible dans le catalogue org)."
}

variable "description" {
  type        = string
  default     = null
  description = "Description libre."
}

variable "source_container_id" {
  type        = string
  default     = null
  description = "UUID du container source à snapshotter en template. Mutuellement exclusif avec `source_vm_id`."
}

variable "source_vm_id" {
  type        = string
  default     = null
  description = "UUID de la VM source à snapshotter en template. Mutuellement exclusif avec `source_container_id`."
}

# Validation cross-field
locals {
  _exactly_one_source = (var.source_container_id != null) != (var.source_vm_id != null)
}

check "exactly_one_source" {
  assert {
    condition     = local._exactly_one_source
    error_message = "Exactement un de `source_container_id` ou `source_vm_id` doit être fourni."
  }
}
