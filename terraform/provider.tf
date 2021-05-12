provider  "aws" {
  version = "= 3.27"
  region = "eu-west-2"
}

provider "vault" {
  address = "https://vault.serokell.org:8200/"
  version = "~> 2.11"
}

data "vault_generic_secret" "hcloud_token" {
  path = "kv/sys/hetzner/tokens/gemini"
}

provider "hcloud" {
  version = "~> 1.22"
  token   = data.vault_generic_secret.hcloud_token.data["token"]
}
