{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-kernel.url = "github:nixos/nixpkgs/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hermes-agent.url = "github:NousResearch/hermes-agent/2bd1977d8fad185c9b4be47884f7e87f1add0ce3";
    kolide-nix-agent = {
      url = "github:kolide/nix-agent/284a398537f71e202037954928cf96c4aef29fe7";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, nixpkgs-kernel, home-manager, hermes-agent, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs-stable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-kernel = import nixpkgs-kernel {
        inherit system;
        config.allowUnfree = true;
      };
      mkNixosConfiguration = module: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs pkgs-stable pkgs-kernel; };
        modules = [
          home-manager.nixosModules.home-manager
          hermes-agent.nixosModules.default
          module
        ];
      };
    in {
      nixosConfigurations = {
        oxygen = mkNixosConfiguration ./configuration.nix;
        phosphorus = mkNixosConfiguration ./phosphorus;
      };
    };
}
