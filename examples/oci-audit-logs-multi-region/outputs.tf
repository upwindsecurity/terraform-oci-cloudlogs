output "home_pointer_stream_name" {
  description = "Name of the home-region pointer stream."
  value       = module.home.pointer_stream_name
}

output "secondary_pointer_stream_name" {
  description = "Name of the secondary-region pointer stream."
  value       = module.secondary.pointer_stream_name
}
