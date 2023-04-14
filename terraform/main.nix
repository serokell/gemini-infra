{ pkgs, lib, ... }:
let
  cluster-name = "gemini";
  inherit (pkgs.lib) mkGress;
in {
  terranix-simple = {
    terraform = {
      enable = true;
      inherit cluster-name;
    };

    state = {
      enable = true;
      inherit cluster-name;
    };

    provider = {
      aws.enable = true;
      hcloud = {
        enable = true;
        hcloud-token = "kv/sys/hetzner/tokens/gemini";
      };
    };

    ami.enable = true;

    aws-route53-zones = {
      enable = true;
      inherit cluster-name;
    };

    vpc = {
      enable = true;
      inherit cluster-name;
      tags = {
        Terraform = "true";
        Environment = "production";
      };
    };
  };

  resource.aws_key_pair.balsoft = {
    key_name = "balsoft";
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDd2OdcSHUsgezuV+cpFqk9+Svtup6PxIolv1zokVZdqvS8qxLsA/rwYmQgTnuq4/zK/GIxcUCH4OxYlW6Or4M4G7qrDKcLAUrRPWkectqEooWRflZXkfHduMJhzeOAsBdMfYZQ9024GwKr/4yriw2BGa8GbbAnQxiSeTipzvXHoXuRME+/2GsMFAfHFvxzXRG7dNOiLtLaXEjUPUTcw/fffKy55kHtWxMkEvvcdyR53/24fmO3kLVpEuoI+Mp1XFtX3DvRM9ulgfwZUn8/CLhwSLwWX4Xf9iuzVi5vJOJtMOktQj/MwGk4tY/NPe+sIk+nAUKSdVf0y9k9JrJT98S/ cardno:000610645773";
  };

  resource.hcloud_ssh_key = {
    zhenya = {
      name = "zhenya";
      public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVESCckOB+2NoojRR+rMl2N4OTf7PQR2BvcxF7cMeRtpSDnMQwbitJNCm0tNygUa8Sn5obaS0HSTfvefIPaDOhgDwi/hGznHiCI3+cAesi/GXXq5p+ota/Ab2oQOFsAquy3sGxNaMhVwU2FU8uyDmiCEbS8kKWAW/YXVqRTPsbkkNBJIwetvzXyrFrYZeCdShZmcPtOGHLpUByKhXkQHXpZ86Bbu9NH/0GsFamADlRaoQQa1+oTWPCWvwsctsAUcHw4/jpeHQffCFATYYS57xYXKkjMZJHypDyjJB9U40bX/HZYaTMP4fDlXeEO/OU2YkAJdt0NBylcE1WzFrOKRNBCcgfgHBzsD3rxMvVNPAl/JXTiEBpXZoza8p+gmQRMMe9SDQLz9pRN7paRsAi1qaQnFV1DbCBPrY2OezJujIuRKc8t0D3nEgg5rcYi2fcFkJscwAsvspTBnK9LCC5ojqa0O5BGTYwlxp2cUkFbWyM2oaRqcQo3ypPaJBybo/TF2FqqHlWNlckwOPPTGngThT6kkFEF+kqMUlUdokiWcpl2K7psfl5RdYGIFfey74NiqoSZ9gyta2WBkY7J41YrsQh20vtGhWWYl/+pDo3cggqmP0fEmD5CaPZXimvHjOjfcxGMooPpkOl3G3I0eQSpvlPpLZHEhh5fThFIAF2RxN/IQ== zhenyavinogradov@gmail.com";
    };

    "notgne2" = {
      name = "notgne2";
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIBwL8/TuE5GT1708sR3rVc1C1g2DmoSf35kjXKKLcr";
    };
  };

  # Allow ALL egress traffic
  resource.aws_security_group =
    let vpc_id = "\${module.vpc.vpc_id}";
    in lib.mapAttrs (name: lib.recursiveUpdate { inherit vpc_id name; }) {
      egress_all = {
        description = "Allow inbound and outbound egress traffic";
        egress = [(mkGress {
          port = 0;
          protocol = "-1";
        })];
      };
      # Allow SSH traffic
      ssh = {
        description = "Allow inbound and outbound traffic for ssh";

        ingress = map mkGress [
          {
            port = 22;
            protocol = "tcp";
          }

          {
            port = 17788;
            protocol = "tcp";
          }
        ];
      };
      # Allow HTTP(S) traffic
      http = {
        description = "Allow inbound and outbound http(s) traffic";

        ingress = map mkGress [
          {
            port = 80;
            protocol = "tcp";
          }

          {
            port = 443;
            protocol = "tcp";
          }
        ];
      };

      # Allow Mumble traffic
      mumble = {
        description = "Allow inbound and outbound traffic of Mumble(Murmur) server";

        ingress = map mkGress [
          {
            port = 64738;
            protocol = "tcp";
          }

          {
            port = 64738;
            protocol = "udp";
          }
        ];
      };

      # Allow wireguard traffic
      wireguard =  {
        description = "Allow inbound and outbound traffic for wireguard";

        ingress = [(mkGress {
          port = 51820;
          protocol = "udp";
        })];
      };
    };
  output.gemini_ns.value = [ "\${aws_route53_zone.gemini_serokell_team.name_servers}" ];

}
