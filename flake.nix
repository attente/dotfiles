{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hermes-agent.url = "github:NousResearch/hermes-agent/498bfc7bc12a937621b4215312049b1000726df3";
    hermes-agent.inputs.nixpkgs.follows = "nixpkgs";
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
