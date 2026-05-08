output "id" {
  description = "UUID du custom template (à utiliser dans `template = ...` des containers/VMs)."
  value       = ccp_custom_template.this.id
}

output "template_type" {
  description = "Type : `lxc` ou `vm`, dérivé de la source."
  value       = ccp_custom_template.this.template_type
}

output "region" {
  description = "Région du template (= région de la source)."
  value       = ccp_custom_template.this.region
}

output "disk_gb" {
  description = "Taille du disque snapshot en GB."
  value       = ccp_custom_template.this.disk_gb
}
