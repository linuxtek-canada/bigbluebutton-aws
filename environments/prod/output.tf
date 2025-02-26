output "state_bucket_arn" {
  description = "The Terraform state bucket where this configuration is stored"
  value       = module.terraform_state_backend.s3_bucket_arn
}