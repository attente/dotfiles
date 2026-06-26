{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hermes-agent.url = "github:NousResearch/hermes-agent/2bd1977d8fad185c9b4be47884f7e87f1add0ce3";
  };

  outputs = { self, nixpkgs, home-manager, hermes-agent, ... }@inputs: {
    nixosConfigurations.oxygen = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        home-manager.nixosModules.home-manager
        hermes-agent.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
