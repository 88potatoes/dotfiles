{
  description = "Eric's Darwin system (multi-machine)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager/d5f1f641b289553927b3801580598d200a501863";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, darwin, nix-homebrew, home-manager }@inputs:
  let
    # ── Shared home-manager config (parameterized by username) ──
    sharedHomeManagerConfig = import ./modules/home-manager.nix;

    # ── Helper: build a darwinConfiguration for a given username ──
    mkDarwinConfig = username:
      darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          (import ./modules/system.nix {
            inherit username nixpkgs-unstable;
            homeManagerUserConfig = (sharedHomeManagerConfig username);
          })
        ];
      };

  in {
    # ── Machine-specific configurations ───────────────────────
    darwinConfigurations = {
      "Mac"     = mkDarwinConfig "ericlang";   # personal laptop
      "Work" = mkDarwinConfig "eric";   # work laptop — update to your work username
    };
  };
}
