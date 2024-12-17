terraform {
    required_providers {
    konnect = {
      source  = "kong/konnect"
      version = "1.0.0"
    }
  }
}

# Control Planes

resource "konnect_gateway_control_plane" "kongair_internal_cp" {
  name         = "KongAir_Internal"
  description  = "CP for the Kong Air Internal API configurations"
  cluster_type = "CLUSTER_TYPE_CONTROL_PLANE"
  auth_type    = "pki_client_certs"

  labels = {
    environment  = var.environment
    team = "kong-air-internal"
    generated_by = "terraform"
  }
}