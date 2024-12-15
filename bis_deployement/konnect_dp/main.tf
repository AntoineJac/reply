locals {
  openshift-project-name           = "kong"
  kong-image-tag                   = "3.1.1.1"
  kong-ingressController-image-tag = "2.7.0"
  kong-helm-version                = "2.13.1"
}

module "openshift-project" {
  source  = "code.siemens.com/ewa_sb/terraform-module-openshift-project/local"
  version = "0.1.4"

  openshift-project-name                   = local.openshift-project-name
  openshift-project-enable-edit-group      = var.openshift-project-enable-edit-group
  openshift-project-admin-users            = var.openshift-project-admin-users
  openshift-project-edit-users             = var.openshift-project-edit-users
  openshift-project-view-users             = var.openshift-project-view-users
  openshift-project-enable-networkpolicies = false
  openshift-project-enable-resourcequota   = false
  resourcequota-hard-limit-cpu             = null
  limitrange-default-cpu                   = null
}


resource "helm_release" "kong-enterprise-data-plane" {
  name      = "kong-enterprise-data-plane"
  namespace = module.openshift-project.namespace

  repository = "https://charts.konghq.com"
  chart      = "kong"
  version    = local.kong-helm-version

  values = [
    "${file("${path.module}/data-plane-values.yaml")}"
  ]

  set {
    name  = "image.tag"
    value = local.kong-image-tag
  }

  set {
    name  = "ingressController.image.tag"
    value = local.kong-ingressController-image-tag
  }

  set {
    name  = "env.admin_api_uri"
    value = "https://admin-kong.${var.openshift-base-url}"
  }

  set {
    name  = "env.proxy_url"
    value = "https://proxy-kong.${var.openshift-base-url}"
  }
  set {
    name  = "env.portal_gui_host"
    value = "portal-kong.${var.openshift-base-url}"
  }

  set {
    name  = "admin.ingress.hostname"
    value = "admin-kong.${var.openshift-base-url}"
  }

  set {
    name  = "manager.ingress.hostname"
    value = "manager-kong.${var.openshift-base-url}"
  }

  set {
    name  = "portal.ingress.hostname"
    value = "portal-kong.${var.openshift-base-url}"
  }

  set {
    name  = "portalapi.ingress.hostname"
    value = "portalapi-kong.${var.openshift-base-url}"
  }

  depends_on = [
    kubernetes_secret.kong-enterprise-license, kubernetes_secret.kong-enterprise-superuser-password, kubernetes_secret.kong-session-config, helm_release.kong-enterprise-control-plane
  ]
}

resource "kubernetes_secret" "kong-tls" {
  metadata {
    name      = "kong-tls"
    namespace = module.openshift-project.namespace

    annotations = merge(var.default-annotations, var.additional-annotations)
    labels      = merge(var.default-labels, var.additional-labels)
  }

  binary_data = {
    "tls.crt" = var.kong-tls-crt
    "tls.key" = var.kong-tls-key
  }

  type = "kubernetes.io/tls"
}

resource "kubernetes_secret" "kong-internal-cluster-cert" {
  metadata {
    name      = "kong-internal-cluster-cert"
    namespace = local.openshift-project-name

    annotations = merge(var.default-annotations, var.additional-annotations)
    labels      = merge(var.default-labels, var.additional-labels)
  }

  binary_data = {
    "tls.crt" = var.kong-internal-cluster-cert
    "tls.key" = var.kong-internal-cluster-cert-key
  }

  type = "kubernetes.io/tls"

  lifecycle {
    ignore_changes = [metadata[0].labels, binary_data]
  }

  depends_on = [
    module.openshift-project
  ]
}

resource "kubernetes_secret" "kong-enterprise-license" {
  metadata {
    name      = "kong-enterprise-license"
    namespace = local.openshift-project-name

    annotations = merge(var.default-annotations, var.additional-annotations)
    labels      = merge(var.default-labels, var.additional-labels)
  }

  data = {
    license = var.kong-enterprise-license
  }

  depends_on = [
    module.openshift-project
  ]
}

resource "kubernetes_secret" "kong-enterprise-superuser-password" {
  metadata {
    name      = "kong-enterprise-superuser-password"
    namespace = local.openshift-project-name

    annotations = merge(var.default-annotations, var.additional-annotations)
    labels      = merge(var.default-labels, var.additional-labels)
  }

  data = {
    password = var.kong-enterprise-superuser-password
  }

  depends_on = [
    module.openshift-project
  ]
}

resource "kubernetes_secret" "kong-session-config" {
  metadata {
    name      = "kong-session-config"
    namespace = local.openshift-project-name

    annotations = merge(var.default-annotations, var.additional-annotations)
    labels      = merge(var.default-labels, var.additional-labels)
  }

  data = {
    admin_gui_session_conf : var.kong-session-config-admin
    portal_session_conf : var.kong-session-config-portal
  }

  depends_on = [
    module.openshift-project
  ]
}
