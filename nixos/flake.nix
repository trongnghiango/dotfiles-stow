{
  description = "NixOS Configuration for Thinkbox";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      thinkbox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/thinkbox/default.nix # (Đường dẫn này tùy vào file flake bạn đang để ở root hay trong nixos)
          
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            
            home-manager.users.ka = import ./home/home.nix;
            home-manager.extraSpecialArgs = { dotfiles = "/home/ka/.dotfiles"; };

            # --- THÊM DÒNG NÀY ĐỂ FIX LỖI ---
            # Nó bảo Home Manager: "Nếu thấy file trùng, hãy đổi tên file cũ thành .backup rồi ghi đè"
            home-manager.backupFileExtension = "backup";
          }
        ];
      };
    };
  };
}
