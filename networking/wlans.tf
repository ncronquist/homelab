# -----------------------------------------------------------------------------
# Wireless Networks (WLANs)
# -----------------------------------------------------------------------------
#
# This file will be populated by importing existing WLANs from the UDM.
#
# To generate import blocks:
#   terrifi generate-imports terrifi_wlan
#
# Example:
#
# resource "terrifi_wlan" "home" {
#   name       = "Home WiFi"
#   security   = "wpapsk"
#   passphrase = var.home_wifi_password  # Use a variable, never hardcode
#   network_id = terrifi_network.default.id
# }
