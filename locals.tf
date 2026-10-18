
locals {
  base_dir = abspath(
    var.output_dir != null ? var.output_dir : "${path.root}/helm"
  )

  app_dir = "${local.base_dir}/${var.name}"

  helmfile_path = "${local.app_dir}/helmfile.yaml.gotmpl"

  values_path = "${local.app_dir}/values/${var.systemenv}.yml"

  remote_helmfile = "git::ssh://git@github.com/${var.helmfile_repo}.git@/helmfile.yaml.gotmpl?ref=${var.helmfile_ref}"
}