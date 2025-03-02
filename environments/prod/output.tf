output "state_bucket_arn" {
  description = "The Terraform state bucket where this configuration is stored"
  value       = module.remote_state.s3_bucket_arn
}