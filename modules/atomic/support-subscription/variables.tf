variable "plan_key" {
  description = "Support plan key: `base`, `standard`, `premium`, or a custom key configured by a CETIC admin."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9_-]{0,19}$", var.plan_key))
    error_message = "plan_key doit être en minuscules (a-z, 0-9, _, -), max 20 caractères."
  }
}
