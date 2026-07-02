output "staging_bucket_name" {
  value       = module.s3_staging.bucket_id
  description = "The name of the staging S3 bucket"
}

output "staging_url" {
  value       = "http://${module.s3_staging.website_endpoint}"
  description = "The URL of the staging S3 website"
}

output "prod_blue_bucket_name" {
  value       = module.s3_prod_blue.bucket_id
  description = "The name of the prod-blue S3 bucket"
}

output "prod_green_bucket_name" {
  value       = module.s3_prod_green.bucket_id
  description = "The name of the prod-green S3 bucket"
}

output "blue_bucket_endpoint" {
  value       = module.s3_prod_blue.website_endpoint
  description = "The S3 website endpoint for the blue bucket"
}

output "green_bucket_endpoint" {
  value       = module.s3_prod_green.website_endpoint
  description = "The S3 website endpoint for the green bucket"
}

output "ssm_parameter_active_color_name" {
  value       = aws_ssm_parameter.active_color.name
  description = "The SSM parameter path tracking the active production color"
}
