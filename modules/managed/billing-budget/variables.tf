variable "monthly_budget_eur" {
  description = "Monthly budget cap in euros (will be converted to cents internally). Example: 50 = 50 €/mois."
  type        = number
  validation {
    condition     = var.monthly_budget_eur > 0
    error_message = "monthly_budget_eur must be > 0."
  }
}

variable "alert_thresholds_pct" {
  description = "Percentage thresholds that trigger email alerts. Default = [50, 80, 100]."
  type        = list(number)
  default     = [50, 80, 100]
}

variable "notify_emails" {
  description = "Email recipients for alerts. If empty, the tenant account email is used."
  type        = list(string)
  default     = []
}

variable "hard_stop_at_100" {
  description = "If true, resource creation is blocked once MTD usage reaches the cap (HTTP 402)."
  type        = bool
  default     = false
}

variable "commit_type" {
  description = "Optional commitment to subscribe to alongside the budget. `null` = no commit, `monthly` = -10%, `yearly` = -20%."
  type        = string
  default     = null
  validation {
    condition     = var.commit_type == null || try(contains(["monthly", "yearly"], var.commit_type), false)
    error_message = "commit_type must be null, monthly, or yearly."
  }
}

variable "commit_auto_renew" {
  description = "If commit_type is set, whether the commitment auto-renews at end_at."
  type        = bool
  default     = true
}
