{
  inputs = {
    # system
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    
    home-manager.url = "sourcehut:~rycee/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    greenhouse.url = "git+https://git.lostduk.com/greenhouse.git";
    greenhouse.flake = false;

    sites.url = "git+https://git.lostduk.com/sites.git";
    sites.flake = false;
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      kore = lib.importJSON ./kore.json;
      palette = import ./palette.nix;

      mkSystem = hostname: host: lib.nixosSystem {
        specialArgs = { inherit inputs outputs kore; };
        modules = [
          ./feats/nixos/base.nix
          ./kore.nix

          ./hosts/${hostname}.nix

          { networking.hostName = hostname; }
        ] ++ lib.optional (host.feats.home or [] != []) ./feats/nixos/home-manager.nix
          ++ map (feat: ./feats/nixos/${feat}.nix) (host.feats.nixos or []);
      };
    in {
      inherit kore palette;

      overlays = import ./overlays { inherit inputs outputs; };

      nixosConfigurations = lib.mapAttrs mkSystem kore.hosts;

      checks.x86_64-linux = let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        hosts = lib.filterAttrs (_: host: host.system == "x86_64-linux") kore.hosts;
      in lib.mapAttrs' (name: _:
        lib.nameValuePair "host-${name}" self.nixosConfigurations.${name}.config.system.build.toplevel
      ) hosts // {
        secrets = pkgs.runCommand "kore-secrets" { nativeBuildInputs = [ pkgs.ssh-to-age ]; } ''
          for host in ${lib.concatStringsSep " " (lib.attrNames kore.hosts)}; do
            key=${./keys/hosts}/$host.pub
            [ -f "$key" ] || { echo "kore: keys/hosts/$host.pub is missing"; exit 1; }
            age=$(ssh-to-age -i "$key")
            grep -q "$age" ${./.sops.yaml} || { echo "kore: $host ($age) is missing from .sops.yaml"; exit 1; }
            grep -q "recipient: $age" ${./secrets/global.yaml} || { echo "kore: secrets/global.yaml is not encrypted to $host, run: sops updatekeys secrets/global.yaml"; exit 1; }
          done
          touch $out
        '';
      };
    };
}
