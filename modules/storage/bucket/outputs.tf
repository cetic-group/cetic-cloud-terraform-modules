output "id" {
  value = ccp_object_bucket.this.id
}

output "name" {
  value = ccp_object_bucket.this.name
}

output "endpoint_url" {
  description = "Endpoint S3 régional (ex `https://s3-rnn.cloud.cetic-group.com`)."
  value       = ccp_object_bucket.this.endpoint_url
}

output "access_key" {
  description = "Master access key (visible côté admin / utilisable dans boto3, etc)."
  value       = ccp_object_bucket.this.access_key
  sensitive   = false
}

output "scoped_keys" {
  description = "Map keyed par label → { access_key, secret_key, access_level }. **Sensitive**."
  value = {
    for k, v in ccp_object_storage_key.scoped : k => {
      access_key   = v.access_key
      secret_key   = v.secret_key
      access_level = v.access_level
    }
  }
  sensitive = true
}
