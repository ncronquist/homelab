# -----------------------------------------------------------------------------
# Networks (VLANs, Subnets)
# -----------------------------------------------------------------------------
#
# This file will be populated by importing existing networks from the UDM.
#
# To generate import blocks:
#   terrifi generate-imports terrifi_network
#
# Example resource (from import):
#
# import {
#   to = terrifi_network.default
#   id = "<network-id>"
# }
#
# resource "terrifi_network" "default" {
#   name         = "Default"
#   purpose      = "corporate"
#   subnet       = "192.168.4.0/24"
#   dhcp_enabled = true
#   dhcp_start   = "192.168.4.100"
#   dhcp_stop    = "192.168.4.254"
#
#   # DNS is handled natively by the UDM — do NOT point DHCP DNS at AdGuard.
#   # Individual service subdomains are managed as A-records in dns.tf.
#   # If you want upstream DNS filtering, set dhcp_dns to a trusted resolver:
#   # dhcp_dns = ["1.1.1.1", "1.0.0.1"]
# }
