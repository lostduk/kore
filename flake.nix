{
  inputs = {
    # system
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    
    home-manager.url = "sourcehut:~rycee/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    greenhouse.url = "git+ssh://git@git.lostduk.com/greenhouse";
    greenhouse.flake = false;
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      kore = lib.importJSON ./kore.json;
    in {
      inherit kore;

      nixosConfigurations = import ./nixos/hosts { inherit inputs outputs lib kore; };
      homeModules = import ./home/profiles { inherit kore; };

      overlays = import ./overlays { inherit inputs outputs; };
    };
}
