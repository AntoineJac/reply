// Outputs of the teams module

output "teams" {
    value = {
        kong_air_internal_devs = konnect_team.kong_air_internal_devs,
        kong_air_internal_viewers = konnect_team.kong_air_internal_viewers,
        kong_air_external_devs = konnect_team.kong_air_external_devs,
        kong_air_external_viewers = konnect_team.kong_air_external_viewers,
        platform_admins = konnect_team.platform_admins,
        platform_viewers = konnect_team.platform_viewers
    }
}