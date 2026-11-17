{
  description = "Minimal NixOS configuration for lithium on Linode";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, disko, ... }: {
    nixosConfigurations.lithium = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ({ modulesPath, ... }: {
          imports = [
            (modulesPath + "/profiles/minimal.nix")
            (modulesPath + "/virtualisation/linode-config.nix")
          ];

          disko.devices.disk.main = {
            device = "/dev/sda";
            type = "disk";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };

          networking.hostName = "lithium";
          swapDevices = [ { device = "/dev/sdb"; } ];
          services.openssh.settings.KbdInteractiveAuthentication = false;
          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJDbwYv/HQpTJJ/OoqLDCOIl/8/OB6PquYTQ1t8I8z4 william@helium"
          ];
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          system.stateVersion = "26.05";
        })
      ];
    };
  };
}
