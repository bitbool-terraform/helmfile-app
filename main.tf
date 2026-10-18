resource "local_file" "environment" {
  filename = local.values_path
  content  = yamlencode(var.env_vars)

  file_permission      = "0600"
  directory_permission = "0755"
}

resource "terraform_data" "helmfile_config" {
  triggers_replace = {
    app_dir        = local.app_dir
    systemenv      = var.systemenv
    remote_helmfile = local.remote_helmfile
  }

  depends_on = [local_file.environment]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      APP_DIR  = local.app_dir
      ENV_NAME = var.systemenv
      GIT_URL  = local.remote_helmfile
    }

    command = <<-SCRIPT
      python3 - <<'PY'
      import os
      import re
      import json
      import fcntl
      import tempfile
      from pathlib import Path

      app_dir = Path(os.environ["APP_DIR"])
      env = os.environ["ENV_NAME"]
      git_url = os.environ["GIT_URL"]

      app_dir.mkdir(parents=True, exist_ok=True)

      helmfile = app_dir / "helmfile.yaml.gotmpl"
      lockfile = app_dir / ".helmfile.lock"
      common = app_dir / "values" / "common.yml"

      stanza = (
          f"  {env}:\n"
          f"    values:\n"
          f"      - values/common.yml\n"
          f"      - values/{env}.yml\n"
      )

      remote_path = json.dumps(git_url)

      with lockfile.open("a+") as lock:
          fcntl.flock(lock, fcntl.LOCK_EX)

          # Optional client-wide defaults.
          common.parent.mkdir(parents=True, exist_ok=True)
          if not common.exists():
              common.write_text("{}\n")

          if not helmfile.exists():
              content = (
                  "environments:\n"
                  + stanza
                  + "\n---\n"
                  + "helmfiles:\n"
                  + f"  - path: {remote_path}\n"
                  + "    inherits:\n"
                  + "      - environments\n"
              )
          else:
              current = helmfile.read_text()

              # Each application uses one central Git reference.
              if f"  - path: {remote_path}" not in current:
                  raise SystemExit(
                      "Existing Helmfile uses another Git URL/ref. "
                      "Refusing to overwrite it."
                  )

              header, separator, body = current.partition("\n---\n")

              if not separator or not re.search(
                  r"(?m)^environments:\s*$", header
              ):
                  raise SystemExit(
                      "Unexpected Helmfile structure; refusing to edit."
                  )

              # Don't duplicate existing environments.
              exists = re.search(
                  rf"(?m)^  {re.escape(env)}:\s*$",
                  header
              )

              if exists:
                  print(f"Environment {env} already exists")
                  raise SystemExit(0)

              content = (
                  header.rstrip("\n")
                  + "\n"
                  + stanza
                  + "\n---\n"
                  + body
              )

          # Atomic replacement, under the shared lock.
          with tempfile.NamedTemporaryFile(
              mode="w",
              dir=app_dir,
              delete=False,
              encoding="utf-8"
          ) as tmp:
              tmp.write(content)
              tmp_path = tmp.name

          os.chmod(tmp_path, 0o644)
          os.replace(tmp_path, helmfile)

          print(f"Registered environment: {env}")
      PY
    SCRIPT
  }
}

resource "terraform_data" "helmfile_apply" {
  count = var.helmfile_apply ? 1 : 0

  triggers_replace = {
    env_hash       = local_file.environment.content_sha256
    helmfile_id    = terraform_data.helmfile_config.id
    apply_token    = var.apply_token
  }

  depends_on = [
    terraform_data.helmfile_config
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    working_dir = local.app_dir

    command = var.helmfile_interactive ? (
        "helmfile -f helmfile.yaml.gotmpl -e ${var.systemenv} --interactive apply </dev/tty"
    ) : (
        "helmfile -f helmfile.yaml.gotmpl -e ${var.systemenv} apply"
    )

    environment = var.kubeconfig_path == null ? {} : {
      KUBECONFIG = pathexpand(var.kubeconfig_path)
    }
  }
}