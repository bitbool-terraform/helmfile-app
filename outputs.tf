output "helmfile_dir" {
  description = "Generated application Helmfile directory"
  value       = local.app_dir
}

output "helmfile_path" {
  description = "Generated Helmfile manifest"
  value       = local.helmfile_path

  depends_on = [terraform_data.helmfile_config]
}

output "values_path" {
  description = "Generated environment-specific values file"
  value       = local_file.environment.filename
}