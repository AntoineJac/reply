variable "openshift-project-enable-edit-group" {
  type    = bool
  default = true
}

variable "openshift-base-url" {
  type = string
}

variable "kong-tls-crt" {
  type = string
}

variable "kong-tls-key" {
  type = string
}

variable "kong-internal-cluster-cert" {
  type = string
}

variable "kong-internal-cluster-cert-key" {
  type = string
}

variable "kong-enterprise-license" {
  type = string
}

variable "kong-enterprise-superuser-password" {
  type = string
}

variable "kong-session-config-admin" {
  type = string
}

variable "kong-session-config-portal" {
  type = string
}

variable "kong-postgres-password" {
  type = string
}

variable "default-labels" {
  type = map(any)

  default = {
    "app.kubernetes.io/managed-by" : "Terraform"
  }
}

variable "additional-labels" {
  type = map(any)

  default = {}
}

variable "default-annotations" {
  type = map(any)

  default = {
    "app.kubernetes.io/managed-by" : "Terraform"
  }
}

variable "additional-annotations" {
  type = map(any)

  default = {}
}

variable "storage-class" {
  type    = string
  default = "nimble-hpe"
}

variable "openshift-project-admin-users" {
  type    = list(string)
  default = []
}

variable "openshift-project-edit-users" {
  type    = list(string)
  default = []
}

variable "openshift-project-view-users" {
  type    = list(string)
  default = []
}

variable "postgres-volume-size" {
  type    = string
  default = "10Gi"
}

variable "postgres-backup-volume-size" {
  type    = string
  default = "10Gi"
}
