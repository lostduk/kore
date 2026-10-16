{
  inputs = {
    # system
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    
    home-manager.url = "sourcehut:~rycee/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    greenhouse.url = "git+https://git.lostduk.com/greenhouse.git";
    greenhouse.flake = false;
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      kore = lib.importJSON ./kore.json;
      palette = import ./palette.nix;
    in {
      inherit kore palette;

      nixosConfigurations = import ./nixos/hosts { inherit inputs outputs lib kore; };
      homeModules = import ./home/profiles { inherit kore; };

      overlays = import ./overlays { inherit inputs outputs; };
    };
}
