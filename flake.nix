{
  description = "A Neovim configuration for the stubborn Nixian hacker";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";

    plugins-blink-ripgrep = {
      url = "github:mikavilpas/blink-ripgrep.nvim";
      flake = false;
    };

    plugins-pomo-nvim = {
      url = "github:epwalsh/pomo.nvim";
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
        # allowUnfree = true;
      };
      inherit
        (forEachSystem (
          system:
          let
            dependencyOverlays = (import ./nix/overlays.nix) ++ [
              # This overlay grabs all the inputs named in the format
              # `plugins-<pluginName>`
              # Once we add this overlay to our nixpkgs, we are able to
              # use `pkgs.neovimPlugins`, which is a set of our plugins.
              (utils.standardPluginOverlay inputs)
              # add any flake overlays here.
            ];
          in
          # these overlays will be wrapped with ${system}
          # and we will call the same utils.eachSystem function
          # later on to access them.
          {
            inherit dependencyOverlays;
          }
        ))
        dependencyOverlays
        ;
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
              python312Packages.pylatexenc
              fd

              # lsps (minimal because should be provided per-project by nix)
              nixd
              tinymist
              elmPackages.elm
              elmPackages.elm-language-server
              arduino-language-server
              clang
              java-language-server

              # formatters
              nixfmt-rfc-style
              nodePackages_latest.prettier
              taplo
              typstyle
              rustfmt
              black
              stylua
              marksman

              libnotify
            ];
          };

          # install lz.n and treesitter grammars
          startupPlugins = {
            gitPlugins = with pkgs.neovimPlugins; [ ];
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
                  jsonc
                  meson
                  nu
                  tsx
                ])
              ))
              # for some reason trigger_load still fails to load this in the
              # proper order
              telescope-ui-select-nvim
            ];
          };

          # plugins which are installed, but not loaded, and will be handled by
          # lz.n (not necessarily lazy loaded)
          optionalPlugins = {
            gitPlugins = with pkgs.neovimPlugins; [
              blink-ripgrep
              pomo-nvim
            ];
            general = with pkgs.vimPlugins; [
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
              texpresso-vim
              blink-cmp
              clangd_extensions-nvim
              tailwind-tools-nvim
              typst-preview-nvim
              lsp-progress-nvim
              lazydev-nvim
              plenary-nvim
              obsidian-nvim
              blink-compat

              # colorschemes
              rose-pine
              oxocarbon-nvim
              kanagawa-nvim
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
                texpresso = "${pkgs.texpresso}/bin/texpresso";
              };
              nixdExtras = {
                nixpkgs = inputs.nixpkgs.outPath;
                flake-path = inputs.self.outPath;
                system = pkgs.system;
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
      in
      {
        packages = utils.mkAllWithDefault defaultPackage;

        devShells = {
          default = pkgs.mkShell {
            name = defaultPackageName;
            packages =
              [ defaultPackage ]
              ++ (with pkgs; [
                lua-language-server
                nixfmt-rfc-style
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
