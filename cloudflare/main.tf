terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.18.0"
    }
  }
}

provider "cloudflare" {}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id = var.cf_account_id
  name = "ai-net"
  config_src = "cloudflare"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "tunnel" {
  account_id = var.cf_account_id
  tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "tunnel_route" {
  account_id         = var.cf_account_id
  tunnel_id          = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  network            = "10.0.0.0/24"
  comment            = "Access to AI DMZ"
}

resource "cloudflare_zero_trust_network_hostname_route" "chat_link" {
  account_id = var.cf_account_id
  comment = "URL to chat web app"
  hostname = "chat.internal"
  tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}
