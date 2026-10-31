{
  description = "A Neovim configuration for the stubborn Nixian hacker";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    # pinned by rev so `nix flake update` can't move opencode (1.19.0) and
    # opencode.nvim (1.0.2): bump them together by editing this rev
    nixpkgs-opencode.url = "github:nixos/nixpkgs/f20cd90e28fe0403873f473b29e42662cd86e8c4";

    plugins-blink-ripgrep = {
      url = "github:mikavilpas/blink-ripgrep.nvim";
      flake = false;
    };

    plugins-pomo-nvim = {
      url = "github:epwalsh/pomo.nvim";
      flake = false;
    };

    plugins-remote-ssh = {
      url = "github:inhesrom/remote-ssh.nvim";
      flake = false;
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixCats,
      ...
    }@inputs:
    let
      inherit (nixCats) utils;
      luaPath = "${./.}";
      forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
      extra_pkg_config = {
        allowUnfree = true;
      };
      # pinned to 1.12: SymbolServer.jl (used by LanguageServer.jl) breaks on 1.13
      # (KeyError :_apply). -bin: source builds fail on darwin (1.13: OpenBLAS tests,
      # 1.12: withPackages writes to $HOME in the sandbox)
      # installCheck runs julia's full test suite, which segfaults in stress.jl on some
      # kernels; withPackages captures the unwrapped julia, so re-point it at ours
      juliaWithLS =
        pkgs:
        let
          julia = pkgs.julia_112-bin.overrideAttrs { doInstallCheck = false; };
        in
        (pkgs.julia_112-bin.withPackages.override { inherit julia; }) [
          "LanguageServer"
          "StaticLint"
          "SymbolServer"
        ];
      opencodePkgs = pkgs: inputs.nixpkgs-opencode.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      # merged over ~/.config/opencode by OPENCODE_CONFIG, so global settings still apply.
      # kaoshung's API has no auth and stays on its loopback: reach it through
      # kaoshung-llm-tunnel.service (127.0.0.1:8090), never a LAN address
      opencodeConfig =
        pkgs:
        pkgs.writeText "opencode.json" (
          builtins.toJSON {
            "$schema" = "https://opencode.ai/config.json";
            provider.kaoshung = {
              npm = "@ai-sdk/openai-compatible";
              name = "kaoshung";
              options = {
                baseURL = "http://127.0.0.1:8090/v1";
                # nothing streams until a cold prompt prefills, up to 90 s at a full window
                timeout = 1800000;
                chunkTimeout = 600000;
              };
              models."Qwen3.8-Flash-Next-Uncensored-exl3-5bpw" = {
                name = "Qwen3.8 Flash Next (kaoshung)";
                tool_call = true;
                reasoning = true;
                attachment = true;
                modalities = {
                  input = [
                    "text"
                    "image"
                  ];
                  output = [ "text" ];
                };
                limit = {
                  context = 131072;
                  output = 32768;
                };
              };
            };
          }
        );
      dependencyOverlays = (import ./nix/overlays.nix) ++ [
        (utils.standardPluginOverlay inputs)
      ];
      # see :help nixCats.flake.outputs.categories
      # and
      # :help nixCats.flake.outputs.categoryDefinitions.scheme
      categoryDefinitions =
        {
          pkgs,
          settings,
          categories,
          name,
          ...
        }@packageDef:
        {
          # lspsAndRuntimeDeps: this section is for dependencies that should be
          # available at RUN TIME for plugins. Will be available to PATH within
          # neovim terminal this includes LSPs
          lspsAndRuntimeDeps = {
            general = with pkgs; [
              # essential
              ripgrep
              python313Packages.pylatexenc
              python313Packages.pynvim
              python313
              tree-sitter
              fd
              (opencodePkgs pkgs).opencode
              openssh
              rsync
              coreutils

              # lsps (minimal because should be provided per-project by nix)
              nixd
              tinymist
              elmPackages.elm
              elmPackages.elm-language-server
              arduino-language-server
              harper
              lua-language-server
              lean4
              metals
              coursier
              clang
              jdt-language-server
              (juliaWithLS pkgs)
              vhdl-ls
              svls
              svelte-language-server
              tailwindcss-language-server
              texlab
              verible
              iverilog
              nushell
              python313Packages.python-lsp-server

              zulu
              # latex

              # formatters
              nixfmt
              prettier
              taplo
              typstyle
              rustfmt
              black
              stylua
              marksman
              google-java-format

              libnotify
            ];
          };

          environmentVariables = {
            general = {
              OPENCODE_CONFIG = "${opencodeConfig pkgs}";
            };
          };

          # install lz.n and treesitter grammars
          startupPlugins = {
            #gitPlugins = with pkgs.neovimPlugins; [ ];
            general = with pkgs.vimPlugins; [
              lz-n
              (nvim-treesitter.withPlugins (
                p:
                (with p; [
                  lua
                  c
                  javascript
                  typescript
                  rust
                  haskell
                  typst
                  latex
                  nix
                  json
                  java
                  toml
                  yaml
                  markdown
                  markdown_inline
                  svelte
                  css
                  html
                  vim
                  bash
                  make
                  gitcommit
                  meson
                  nu
                  tsx
                  scala
                  python
                  julia
                  systemverilog
                ])
              ))
              # for some reason trigger_load still fails to load this in the
              # proper order
              telescope-ui-select-nvim
              telescope-fzf-native-nvim
              nvim-metals
            ];
          };

          # plugins which are installed, but not loaded, and will be handled by
          # lz.n (not necessarily lazy loaded)
          optionalPlugins = {
            gitPlugins = with pkgs.neovimPlugins; [
              blink-ripgrep
              pomo-nvim
              remote-ssh
            ];
            general = with pkgs.vimPlugins; [
              # orgmode
              verilog_systemverilog-vim
              nvim-autopairs
              nvim-lspconfig
              which-key-nvim
              telescope-nvim
              markdown-preview-nvim
              render-markdown-nvim
              nvim-web-devicons
              oil-nvim
              harpoon2
              toggleterm-nvim
              trouble-nvim
              lualine-nvim
              bufferline-nvim
              nvim-tree-lua
              mini-ai
              mini-hipatterns
              mini-surround
              mini-starter
              cellular-automaton-nvim
              indent-blankline-nvim
              fidget-nvim
              mini-bufremove
              neogit
              gitsigns-nvim
              barbecue-nvim
              undotree
              conform-nvim
              neocord
              rustaceanvim
              crates-nvim
              haskell-tools-nvim
              lsp_lines-nvim
              vim-sleuth
              typescript-tools-nvim
              blink-cmp
              tailwind-tools-nvim
              typst-preview-nvim
              lsp-progress-nvim
              lazydev-nvim
              plenary-nvim
              obsidian-nvim
              blink-compat
              nvim-metals
              vim-scala
              vim-wakatime
              # colorschemes
              rose-pine
              oxocarbon-nvim
              kanagawa-nvim
              (opencodePkgs pkgs).vimPlugins.opencode-nvim
            ];
          };

          # shared libraries to be added to LD_LIBRARY_PATH
          # variable available to nvim runtime
          sharedLibraries = {
            general = with pkgs; [
              # libgit2
            ];
          };
        };
      packageDefinitions = {
        nvim =
          { pkgs, ... }:
          {
            settings = {
              wrapRc = true;
              aliases = [
                "vim"
                "vi"
              ];
            };
            categories = {
              general = true;
              gitPlugins = true;
              customPlugins = true;
              bin = {
                websocat = "${pkgs.websocat}/bin/websocat";
                tinymist = "${pkgs.tinymist}/bin/tinymist";
                # julials must use the julia that has LanguageServer, not whatever is first on PATH
                julia = "${juliaWithLS pkgs}/bin/julia";
              };
              nixdExtras = {
                nixpkgs = inputs.nixpkgs.outPath;
                flake-path = inputs.self.outPath;
                system = pkgs.stdenv.hostPlatform.system;
              };
            };
          };
        nvim-no-rc =
          { pkgs, ... }:
          {
            settings = {
              wrapRc = false;
              aliases = [ ];
            };
            categories = {
              general = true;
              gitPlugins = true;
              nixdExtras = {
                nixpkgs = inputs.nixpkgs.outPath;
                flake-path = inputs.self.outPath;
                system = pkgs.stdenv.hostPlatform.system;
              };
            };
          };
      };
      defaultPackageName = "nvim";
    in
    forEachSystem (
      system:
      let
        nixCatsBuilder = utils.baseBuilder luaPath {
          inherit
            nixpkgs
            system
            dependencyOverlays
            extra_pkg_config
            ;
        } categoryDefinitions packageDefinitions;
        defaultPackage = nixCatsBuilder defaultPackageName;
        pkgs = import nixpkgs { inherit system; };
        fullscreenLauncher = pkgs.writeShellApplication {
          name = "nvim-fullscreen";
          text = ''
            exec ${pkgs.kitty}/bin/kitty --start-as fullscreen --class viminal2 \
              ${defaultPackage}/bin/nvim "$@"
          '';
        };
      in
      {
        packages = utils.mkAllWithDefault defaultPackage // {
          fullscreen = fullscreenLauncher;
        };

        apps.fullscreen = {
          type = "app";
          program = "${fullscreenLauncher}/bin/nvim-fullscreen";
          meta.description = "Open Neovim in a fullscreen Kitty window";
        };

        devShells = {
          default = pkgs.mkShell {
            name = defaultPackageName;
            packages = [
              defaultPackage
            ]
            ++ (with pkgs; [
              lua-language-server
              nixfmt
              stylua
            ]);
          };
        };

        formatter = pkgs.treefmt;
      }
    )
    // {
      overlays = utils.makeOverlays luaPath {
        inherit nixpkgs dependencyOverlays extra_pkg_config;
      } categoryDefinitions packageDefinitions defaultPackageName;

      nixosModules.default = utils.mkNixosModules {
        inherit
          defaultPackageName
          dependencyOverlays
          luaPath
          categoryDefinitions
          packageDefinitions
          extra_pkg_config
          nixpkgs
          ;
      };
      homeModule = utils.mkHomeModules {
        inherit
          defaultPackageName
          dependencyOverlays
          luaPath
          categoryDefinitions
          packageDefinitions
          extra_pkg_config
          nixpkgs
          ;
      };
      inherit utils;
      inherit (utils) templates;
    };

}
