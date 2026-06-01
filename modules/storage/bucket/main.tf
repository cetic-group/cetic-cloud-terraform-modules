resource "ccp_object_bucket" "this" {
  provider  = ccp
  name      = var.name
  region    = var.region
  is_public = var.is_public
  tags      = var.tags
}

# Clés scopées (subusers) — tenant-wide en v1, mais scopées par access_level.
# Note : v1 = tenant-wide ; per-bucket policies viendront en v2 (cf. backlog).
resource "ccp_object_storage_key" "scoped" {
  provider = ccp
  for_each = var.scoped_keys

  region       = var.region
  label        = each.key
  access_level = each.value.access_level

  # Le bucket doit exister avant la création des clés (même région)
  depends_on = [ccp_object_bucket.this]
}
