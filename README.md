## helmfile-app

Sample module ref:

```terraform
module "helmfile-app" {
  for_each = { for k,v in local.helmfile_apps: k=>v if ( (lookup(v,"enabled",true) != false)) }
  source = source = "git::https://github.com/bitbool-terraform/helmfile-app.git?ref=<VERSION_REF>"

  name      = format("%s-%s",local.name_prefix, each.key)
  systemenv = var.systemenv

  helmfile_repo = each.value.repo
  helmfile_ref  = each.value.repo_ref

  # Generate beside the terraform directory
  # output_dir = "${path.root}/../helm"

  env_vars = each.value.env_vars

  helmfile_apply  = var.helmfile_apply
  kubeconfig_path = var.kubeconfig_path
}
```
