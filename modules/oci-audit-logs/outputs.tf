# region outputs

output "bucket_name" {
  description = "Name of the bucket receiving the log objects."
  value       = oci_objectstorage_bucket.this.name
}

output "pointer_stream_name" {
  description = "Name of the stream carrying one pointer per new log object."
  value       = oci_streaming_stream.pointers.name
}

output "pointer_stream_id" {
  description = "OCID of the pointer stream."
  value       = oci_streaming_stream.pointers.id
}

output "enabled_log_types" {
  description = "The enabled log types: AUDIT, IDENTITY."
  value       = local.log_types
}

output "policy_id" {
  description = "OCID of this region's IAM policy."
  value       = oci_identity_policy.this.id
}

# endregion outputs
