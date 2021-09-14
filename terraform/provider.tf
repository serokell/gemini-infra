provider  "aws" {
  region = "eu-west-2"
}

provider "vault" {
  address = "https://vault.serokell.org:8200/"
}

data "vault_generic_secret" "hcloud_token" {
  path = "kv/sys/hetzner/tokens/gemini"
}

provider "hcloud" {
  token   = data.vault_generic_secret.hcloud_token.data["token"]
}
