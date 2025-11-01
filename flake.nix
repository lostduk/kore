{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    
    home-manager.url = "sourcehut:~rycee/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;
    in {
      nixosConfigurations = import ./nixos/hosts { inherit inputs outputs lib; };
      homeConfigurations = import ./home/profiles;

      overlays = import ./overlays { inherit inputs outputs; };
    };
}
