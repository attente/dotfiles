{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hermes-agent.url = "github:NousResearch/hermes-agent/2bd1977d8fad185c9b4be47884f7e87f1add0ce3";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, hermes-agent, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs-stable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
    nixosConfigurations.oxygen = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs pkgs-stable; };
      modules = [
        home-manager.nixosModules.home-manager
        hermes-agent.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
