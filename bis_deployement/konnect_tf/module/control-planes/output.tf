// Outputs for the control planes module
output "control_planes" {
  value = {
    standard = {
      kongair_internal_cp = konnect_gateway_control_plane.kongair_internal_cp,
      kongair_external_cp = konnect_gateway_control_plane.kongair_external_cp,
      kongair_global_cp = konnect_gateway_control_plane.kongair_global_cp
    },
    groups = {
      kongair_internal_cp_group = konnect_gateway_control_plane.kongair_internal_cp_group,
      kongair_external_cp_group = konnect_gateway_control_plane.kongair_external_cp_group
    }
  }
}