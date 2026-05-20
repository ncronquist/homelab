# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "macbook_ip" {
  description = "Static LAN IP of the MacBook Pro running OrbStack and Caddy. All homelab service DNS A-records point here."
  type        = string
  default     = "192.168.4.31"
}

variable "home_domain" {
  description = "Internal subdomain suffix for all homelab services."
  type        = string
  default     = "home.ncronquist.com"
}
