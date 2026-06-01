resource "ccp_registry" "this" {
  provider       = ccp
  name           = var.name
  region         = var.region
  expose_public  = var.expose_public
  expose_private = var.expose_private
  image_tag      = var.image_tag
  tags           = var.tags

  lifecycle {
    precondition {
      condition     = var.expose_public || var.expose_private
      error_message = "At least one of expose_public / expose_private must be true."
    }
  }
}
