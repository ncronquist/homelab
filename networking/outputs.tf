# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
# Outputs will be populated as resources are imported from the live UDM.
#
# Example outputs to add after importing:
#
# output "default_network_id" {
#   description = "ID of the default network"
#   value       = terrifi_network.default.id
# }
#
# output "wlan_names" {
#   description = "Names of all managed WLANs"
#   value       = [for w in terrifi_wlan.managed : w.name]
# }
