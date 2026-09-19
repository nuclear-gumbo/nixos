{
  description = "The whole kit n kaboodle";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    home-managerU = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-managerS = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    #    noctalia = {
    #      url = "github:noctalia-dev/noctalia-shell/";
    #      inputs.nixpkgs.follows = "nixpkgs-unstable";
    #    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs-stable";

    comin.url = "github:nlewo/comin";
    comin.inputs.nixpkgs.follows = "nixpkgs-stable";

    second-brain.url = "github:nuclear-gumbo/second-brain";
    second-brain.inputs.nixpkgs.follows = "nixpkgs-stable";

    wiki.url = "git+https://git.zorse-ruffe.ts.net/sensei/wiki";
    wiki.inputs.nixpkgs.follows = "nixpkgs-stable";

    aliased.url = "git+https://git.zorse-ruffe.ts.net/sensei/aliased";
    aliased.inputs.nixpkgs.follows = "nixpkgs-stable";
  };

  outputs =
    {
      self,
      nixpkgs-unstable,
      nixpkgs-stable,
      home-managerU,
      home-managerS,
      sops-nix,
      flatpaks,
      disko,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      libU = nixpkgs-unstable.lib;
      libS = nixpkgs-stable.lib;

      overlays = [
        (final: prev: {
          future-cursors = prev.callPackage ./pkgs/future-cursor.nix { };
        })
      ];

      # shared host builder
      mkHost =
        {
          lib,
          deviceModule,
          modules ? [ ],
          hm ? [ ],
        }:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = overlays; }
            deviceModule
          ]
          ++ modules
          ++ [
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "bak";
                extraSpecialArgs = { inherit inputs; };
                sharedModules = [
                  (
                    { osConfig, ... }:
                    {
                      _module.args.hostName = osConfig.networking.hostName;
                    }
                  )
                ];
                users.gumbo.imports = hm;
              };
            }
          ];
        };

      # workstations on unstable, import hm common files here
      mkWorkstation =
        {
          deviceModule,
          hm ? [ ],
          modules ? [ ],
        }:
        mkHost {
          lib = libU;
          inherit deviceModule;
          modules = [
            home-managerU.nixosModules.home-manager
            disko.nixosModules.disko
            flatpaks.nixosModules.default
            sops-nix.nixosModules.default
          ]
          ++ modules;
          hm = [
            ./home/common.nix
            ./home/zsh.nix
          ]
          ++ hm;
        };

      # servers on stable, import defaults (ssh, baseline, etc)
      mkServer =
        {
          deviceModule,
          hm ? [ ],
          modules ? [ ],
        }:
        mkHost {
          lib = libS;
          inherit deviceModule;
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.default
            ./modules/baseline.server.nix
            ./modules/ssh.nix
            ./modules/svc.nix
            ./modules/cd.nix
            ./modules/cache.nix
            ./modules/reboot.nix
            ./modules/dns.nix
            ./modules/killswitch.nix
            ./modules/ban.nix
            ./modules/ntp.nix
            home-managerS.nixosModules.home-manager
          ]
          ++ modules;
          hm = [
            ./home/server.nix
            ./home/zsh.nix
          ]
          ++ hm;
        };
    in
    {
      formatter.${system} = nixpkgs-unstable.legacyPackages.${system}.nixfmt-tree;

      nixosConfigurations = {
        # erebos = mkWorkstation {
        #   deviceModule = ./machines/desktop/erebos/default.nix;
        #   hm = [ ./home/kde.nix ];
        # };

        # prometheus = mkWorkstation {
        #   deviceModule = ./machines/laptop/prometheus/default.nix;
        #   hm = [ ./home/niri.nix ];
        # };

        console = mkWorkstation {
          deviceModule = ./machines/desktop/console/default.nix;
          hm = [ ./home/kde.nix ];
        };

        srv-n1 = mkServer {
          deviceModule = ./machines/server/srv-n1/default.nix;
        };

        srv-n2 = mkServer {
          deviceModule = ./machines/server/srv-n2/default.nix;
        };

        srv-n3 = mkServer {
          deviceModule = ./machines/server/srv-n3/default.nix;
        };

        pangolin = mkServer {
          deviceModule = ./machines/server/pangolin/default.nix;
        };

        aliased = mkServer {
          deviceModule = ./machines/server/aliased/default.nix;
        };

        wazuh = mkServer {
          deviceModule = ./machines/server/wazuh/default.nix;
        };

        # k3s-a1 = mkServer {
        #   deviceModule = ./machines/server/k3s/k3s-a1/default.nix;
        # };

        # k3s-a2 = mkServer {
        #   deviceModule = ./machines/server/k3s/k3s-a2/default.nix;
        # };

        # k3s-a3 = mkServer {
        #   deviceModule = ./machines/server/k3s/k3s-a3/default.nix;
        # };

        # k3s-a4 = mkServer {
        #   deviceModule = ./machines/server/k3s/k3s-a4/default.nix;
        # };

        # k3s-s1 = mkServer {
        #   deviceModule = ./machines/server/k3s/k3s-s1/default.nix;
        # };

        jellyfin = mkServer {
          deviceModule = ./machines/lxc/jellyfin/default.nix;
        };

        runner = mkServer {
          deviceModule = ./machines/lxc/runner/default.nix;
        };

        second-brain = mkServer {
          deviceModule = ./machines/lxc/second-brain/default.nix;
        };

        mongoose = mkServer {
          deviceModule = ./machines/lxc/mongoose/default.nix;
        };

        filebrowser = mkServer {
          deviceModule = ./machines/lxc/filebrowser/default.nix;
        };
      };
    };
}
