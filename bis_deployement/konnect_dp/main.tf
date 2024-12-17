locals {
  project-name           = "kong"
  kong-image-tag                   = "3.1.1.1"
  kong-ingressController-image-tag = "2.7.0"
  kong-helm-version                = "2.13.1"
}


resource "helm_release" "kong-enterprise-data-plane" {
  name      = "kong-enterprise-data-plane"
  namespace = "kong"

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

  depends_on = [
    kubernetes_secret.kong-enterprise-license, kubernetes_secret.kong-enterprise-superuser-password, kubernetes_secret.kong-session-config, helm_release.kong-enterprise-control-plane
  ]
}

resource "kubernetes_secret" "kong-tls" {
  metadata {
    name      = "kong-tls"
    namespace = local.project-name

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
    namespace = local.project-name

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

}

resource "kubernetes_secret" "kong-enterprise-license" {
  metadata {
    name      = "kong-enterprise-license"
    namespace = local.project-name

    annotations = merge(var.default-annotations, var.additional-annotations)
    labels      = merge(var.default-labels, var.additional-labels)
  }

  data = {
    license = var.kong-enterprise-license
  }

}

resource "kubernetes_secret" "kong-enterprise-superuser-password" {
  metadata {
    name      = "kong-enterprise-superuser-password"
    namespace = local.project-name

    annotations = merge(var.default-annotations, var.additional-annotations)
    labels      = merge(var.default-labels, var.additional-labels)
  }

  data = {
    password = var.kong-enterprise-superuser-password
  }

}

resource "kubernetes_secret" "kong-session-config" {
  metadata {
    name      = "kong-session-config"
    namespace = local.project-name

    annotations = merge(var.default-annotations, var.additional-annotations)
    labels      = merge(var.default-labels, var.additional-labels)
  }

  data = {
    admin_gui_session_conf : var.kong-session-config-admin
    portal_session_conf : var.kong-session-config-portal
  }

}
