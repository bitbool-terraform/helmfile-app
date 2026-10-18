## helmfile-app

Sample module ref:

```terraform
module "helmfile-superset" {
  source = "./modules/helmfile-app"

  name      = "superset"
  systemenv = var.systemenv

  helmfile_repo = "my-org/helmfile-superset"
  helmfile_ref  = "v1.4.0"

  # Generate beside the terraform directory
  # output_dir = "${path.root}/../helm"

  env_vars = {
    superset = {
      namespace      = "${var.systemenv}-superset"
      workerReplicas = 2

      image = {
        tag = "custom-1.0"
      }
    }
  }

  helmfile_apply  = false
  kubeconfig_path = "~/.kube/....yaml"
}
```
