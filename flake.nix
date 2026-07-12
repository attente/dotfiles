{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hermes-agent.url = "github:NousResearch/hermes-agent/2bd1977d8fad185c9b4be47884f7e87f1add0ce3";
    kolide-launcher.url = "github:kolide/nix-agent/main";
    kolide-launcher.inputs.nixpkgs.follows = "nixpkgs";
    falcon-sensor.url = "github:vtechev/crowdstrike-falcon-nix";
    falcon-sensor.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, hermes-agent, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs-stable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
      commonModules = [
        home-manager.nixosModules.home-manager
        hermes-agent.nixosModules.default
        inputs.kolide-launcher.nixosModules.kolide-launcher
        inputs.falcon-sensor.nixosModules.default
        ./configuration.nix
      ];
    in {
      nixosConfigurations = {
        oxygen = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs pkgs-stable; };
          modules = commonModules ++ [
            {
              imports = [ ./oxygen/hardware-configuration.nix ];
              networking.hostName = "oxygen";
              system.stateVersion = "25.11";
              home-manager.users.william.home.stateVersion = "25.11";
              boot.kernelPackages = nixpkgs.legacyPackages.${system}.linuxPackages_latest;
              boot.initrd.kernelModules = [
                "amdgpu"
                "lm92"
                "nct6775"
              ];
              boot.kernelParams = [
                "video=DP-1:1920x1080@60"
                "video=DP-2:1920x1080@60"
              ];
              services.hermes-agent.enable = true;
            }
          ];
        };

        phosphorus = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs pkgs-stable; };
          modules = commonModules ++ [
            {
              imports = [ ./phosphorus/hardware-configuration.nix ];
              networking.hostName = "phosphorus";
              system.stateVersion = "26.05";
              home-manager.users.william.home.stateVersion = "26.05";
              boot.kernelPackages = nixpkgs.legacyPackages.${system}.linuxPackages_6_18;
              home-manager.users.william.services.hypridle.settings.general.after_sleep_cmd = "hyprlock --immediate --no-fade-in";
              services.kolide-launcher.enable = true;
              services.falcon-sensor.enable = true;
            }
          ];
        };
      };
    };
}
