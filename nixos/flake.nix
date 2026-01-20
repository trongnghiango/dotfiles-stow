{
  description = "NixOS Configuration for Thinkbox - The Arch Way";

  inputs = {
    # Dùng nhánh unstable để phần mềm luôn mới nhất (Rolling Release)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      thinkbox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/thinkbox/default.nix
          
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ka = import ./home/home.nix;
            
            # Truyền đường dẫn tuyệt đối của dotfiles vào home.nix
            home-manager.extraSpecialArgs = { dotfiles = "/home/ka/.dotfiles"; };
          }
        ];
      };
    };
  };
}
