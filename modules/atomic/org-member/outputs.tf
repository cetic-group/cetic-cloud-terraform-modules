output "id" {
  description = "UUID du membre."
  value       = ccp_org_member.this.id
}

output "accepted" {
  description = "Si `true`, le membre a accepté l'invitation (le compte CCP avec cet email existe)."
  value       = ccp_org_member.this.accepted
}

output "accepted_at" {
  description = "Timestamp d'acceptation (RFC3339), ou `null` si l'invitation est encore pending."
  value       = ccp_org_member.this.accepted_at
}
