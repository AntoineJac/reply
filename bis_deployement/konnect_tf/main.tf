terraform {
  required_providers {
    konnect = {
      source  = "kong/konnect"
      version = "1.0.0"
    }
  }
}

module "control_planes" {
  source      = "./modules/control-planes"
  environment = var.environment
}

# module "teams" {
#   source         = "./modules/teams"
#   environment    = var.environment
#   control_planes = module.control_planes.control_planes
# }