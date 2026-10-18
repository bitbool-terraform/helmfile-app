variable "name" {
  description = "Application name, e.g. superset"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]*$", var.name))
    error_message = "Invalid application name."
  }
}

variable "systemenv" {
  description = "Environment name, e.g. staging, production"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]*$", var.systemenv))
    error_message = "Invalid environment name."
  }
}

variable "env_vars" {
  description = "Values for this environment, serialized with yamlencode()"
  type        = any
}

variable "helmfile_repo" {
  description = "GitHub repository, in org/repository format"
  type        = string

  validation {
    condition = can(regex(
      "^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$",
      var.helmfile_repo
    ))
    error_message = "Expected GitHub repository: org/repository."
  }
}

variable "helmfile_ref" {
  description = "Git tag, branch or commit of the central Helmfile"
  type        = string
  default     = "main"
}

variable "helmfile_apply" {
  description = "Run helmfile apply after generating files"
  type        = bool
  default     = false
}

variable "helmfile_interactive" {
  description = "Ask for confirmation before Helmfile changes"
  type        = bool
  default     = false
}

variable "kubeconfig_path" {
  description = "Optional Kubernetes kubeconfig path"
  type        = string
  default     = null
}

variable "output_dir" {
  description = "Base directory for generated application Helmfiles"
  type        = string
  default     = null
}

variable "apply_token" {
  description = "Change this value to manually trigger another Helmfile apply"
  type        = string
  default     = ""
}