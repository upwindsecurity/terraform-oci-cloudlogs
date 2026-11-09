output "pointer_stream_name" {
  description = "Name of the pointer stream."
  value       = module.oci_audit_logs.pointer_stream_name
}

output "bucket_name" {
  description = "Name of the log bucket."
  value       = module.oci_audit_logs.bucket_name
}
