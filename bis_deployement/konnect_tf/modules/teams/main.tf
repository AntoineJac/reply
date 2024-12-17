terraform {
    required_providers {
    konnect = {
      source  = "kong/konnect"
      version = "1.0.0"
      # configuration_aliases = [konnect.global]
    }
  }
}

# Teams

# Internal Developers Team

resource "konnect_team" "kong_air_internal_devs" {
  description = "Allow managing the internal control plane configurations"
  name        = "Kong Air Internal Developers"
}