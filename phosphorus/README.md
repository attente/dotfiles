# phosphorus

Before switching phosphorus to this flake, preserve the existing security-agent
state:

```sh
sudo tar -C / -cpf ~/phosphorus-security-agent-state.tar \
  etc/kolide-k2/secret \
  etc/falcon-sensor.env \
  opt/CrowdStrike
```

Make sure the Falcon package is available to `pkgs.requireFile`:

```sh
nix-store --add-fixed sha256 ./kolide-falcon/falcon-sensor_7.31.0-18410_amd64.deb
```

The files under `kolide-falcon/` are local migration copies and are ignored by
Git because they include proprietary or secret material.

The runtime files should remain in place on phosphorus:

```sh
sudo install -d -m 0755 /etc/kolide-k2
sudo install -m 0600 ./kolide-falcon/etc-kolide-k2-secret /etc/kolide-k2/secret
sudo install -m 0600 ./kolide-falcon/falcon-sensor.env /etc/falcon-sensor.env
```

Then switch with:

```sh
sudo nixos-rebuild switch --flake .#phosphorus
```
