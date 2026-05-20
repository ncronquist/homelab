# -----------------------------------------------------------------------------
# Firewall Zones & Policies
# -----------------------------------------------------------------------------
#
# This file will be populated by importing existing firewall configuration.
#
# To generate import blocks:
#   terrifi generate-imports terrifi_firewall_zone
#   terrifi generate-imports terrifi_firewall_policy
#
# Example zone:
#
# resource "terrifi_firewall_zone" "internal" {
#   name = "Internal"
# }
#
# Example policy:
#
# resource "terrifi_firewall_policy" "allow_internal_to_internet" {
#   name        = "Allow Internal to Internet"
#   action      = "accept"
#   source_zone = terrifi_firewall_zone.internal.id
#   # ... additional fields from import
# }
