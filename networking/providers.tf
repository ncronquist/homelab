terraform {
  required_version = ">= 1.5"

  required_providers {
    terrifi = {
      source  = "alexklibisz/terrifi"
      version = "~> 0.2"
    }
  }
}

provider "terrifi" {
  # Authentication and connection configured via environment variables:
  #
  #   UNIFI_API      - UDM controller URL (e.g., https://192.168.1.1)
  #   UNIFI_API_KEY  - API key for authentication (recommended over username/password)
  #   UNIFI_INSECURE - Set to "true" for self-signed certificates
  #   UNIFI_SITE     - UniFi site name (default: "default")
  #
  # See .env.example for a template.

  allow_insecure   = true  # UDM uses self-signed certificates
  response_caching = true  # Improves performance for plan/apply
}
