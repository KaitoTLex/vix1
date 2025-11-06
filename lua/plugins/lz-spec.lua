return {
  require("plugins.blink-cmp"),
  require("plugins.telescope"),
  require("plugins.oil"),
  require("plugins.harpoon"),
  require("plugins.lualine"),
  require("plugins.conform"),
  -- require("plugins.lsp-progress"),
  require("plugins.orgmode"),
  require("plugins.gitsigns"),
  require("plugins.autopairs"),
  require("plugins.trouble"),
  require("plugins.render-markdown"),
  require("plugins.toggleterm"),
  require("plugins.neogit"),
  require("plugins.obsidian"),
  require("plugins.starter"),
  { "vim-wakatime" },
  { "vim-sleuth" },
  {
    "nvim-lspconfig",
    event = "BufEnter",
    after = require("lsp").setup,
  },
  {
    "which-key.nvim",
    after = function()
      require("which-key").setup({
        delay = 1000,
      })
    end,
  },
  { "nvim-web-devicons" },
  {
    "markdown-preview.nvim",
    filetypes = { "markdown" },
  },
  {
    "typst-preview.nvim",
    filetypes = { "*.typ" },
    after = function()
      require("typst-preview").setup({
        dependencies_bin = {
          ["tinymist"] = nixCats("bin.tinymist"),
          ["websocat"] = nixCats("bin.websocat"),
        },
      })
    end,
  },
  {
    "mini.ai",
    event = "BufEnter",
    after = function()
      require("mini.ai").setup()
    end,
  },
  {
    "mini.surround",
    event = "BufEnter",
    after = function()
      require("mini.surround").setup()
    end,
  },
  {
    "fidget.nvim",
    after = function()
      require("fidget").setup({
        notification = {
          override_vim_notify = true,
          window = {
            border = "rounded",
            x_padding = 1,
            y_padding = 2,
          },
        },
      })
    end,
  },
  {
    "cellular-automaton.nvim",
    cmd = "CellularAutomaton",
    keys = {
      {
        "<leader>mr",
        function()
          vim.cmd.CellularAutomaton("make_it_rain")
        end,
        desc = "A surprise!",
        mode = "n",
      },
      {
        "<leader>bruh",
        function()
          vim.cmd.CellularAutomaton("game_of_life")
        end,
        desc = "A surprise!",
        mode = "n",
      },
    },
  },
  {
    "indent-blankline.nvim",
    after = function()
      require("ibl").setup({
        indent = {
          char = "│",
          tab_char = "│",
        },
        scope = { show_start = false, show_end = false },
        exclude = {
          filetypes = {
            "help",
            "ministarter",
            "Trouble",
            "trouble",
            "toggleterm",
          },
        },
      })
    end,
  },
  {
    "mini.bufremove",
    keys = {
      {
        "<leader>bd",
        function()
          MiniBufremove.delete()
        end,
        mode = { "n", "v" },
        desc = "Close buffer",
      },
    },
    after = function()
      require("mini.bufremove").setup()
    end,
  },
  {
    "mini.hipatterns",
    event = "BufEnter",
    after = function()
      require("mini.hipatterns").setup()
    end,
  },
  {
    "barbecue.nvim",
    event = "BufEnter",
    after = function()
      require("barbecue").setup()
    end,
  },
  {
    "undotree",
    cmd = "UndotreeToggle",
    keys = {
      {
        "<leader>u",
        function()
          vim.cmd.UndotreeToggle()
        end,
        desc = "Toggle undotree",
        mode = "n",
      },
    },
  },
  {
    "neocord",
    event = "BufEnter",
    after = function()
      require("neocord").setup({
        editing_text = "Hacking %s",
        logo_tooltip = "The One True Text Editor",
        terminal_text = "Bypassing the mainframe",
        workspace_text = "The One True Text Editor",
      })
    end,
  },
  {
    "crates.nvim",
    event = "BufRead Cargo.toml",
    after = function()
      require("crates").setup({})
    end,
  },
  { "rustaceanvim" },
  { "haskell-tools.nvim" },
  {
    "typescript-tools.nvim",
    filetypes = { "typescriptreact", "typescript", "javascript", "svelte", "javascriptreact" },
    after = function()
      require("lz.n").trigger_load("nvim-lspconfig")
      require("typescript-tools").setup({})
    end,
  },
  {
    "lsp_lines.nvim",
    event = "LspAttach",
    after = function()
      require("lsp_lines").setup()
      vim.diagnostic.config({
        virtual_text = false,
        virtual_lines = { only_current_line = true },
      })
    end,
  },
  { "blink-ripgrep", lazy = true },
  { "blink.compat", lazy = true },
  {
    "lazydev.nvim",
    filetypes = { "lua" },
    after = function()
      require("lazydev").setup()
    end,
  },
  {
    "rose-pine",
    colorscheme = { "rose-pine", "rose-pine-dawn", "rose-pine-moon", "rose-pine-main" },
  },
  {
    "oxocarbon.nvim",
    colorscheme = { "oxocarbon" },
  },
  --   { "verilog_systemverilog.vim"
  -- let g:verilog_syntax_fold_lst = "all"
  -- set foldmethod=syntax
  --   },
  {
    "pomo-nvim",
    cmd = { "TimerStart", "TimerRepeat", "TimerSession" },
    after = function()
      ---@diagnostic disable-next-line: missing-fields
      require("pomo").setup({
        notifiers = {
          {
            name = "Default",
            opts = {
              sticky = false,
            },
          },
          { name = "System" },
        },
        sessions = {
          pomodoro = {
            { name = "Work", duration = "25m" },
            { name = "Short Break", duration = "5m" },
            { name = "Work", duration = "25m" },
            { name = "Short Break", duration = "5m" },
            { name = "Work", duration = "25m" },
            { name = "Long Break", duration = "15m" },
          },
          grind = {
            { name = "Work", duration = "45m" },
            { name = "Short Break", duration = "5m" },
            { name = "Work", duration = "45m" },
          },
        },
      })
    end,
    keys = {
      {
        "<leader>fp",
        function()
          require("telescope").load_extension("pomodori")
          require("telescope").extensions.pomodori.timers()
        end,
        desc = "Manage Pomodori Timers",
      },
    },
  },
  {
    "scalameta/nvim-metals",
    ft = { "scala", "sbt", "java" },
    opts = function()
      local metals_config = require("metals").bare_config()
      metals_config.on_attach = function(client, bufnr)
        -- your on_attach function
      end
      return metals_config
    end,
    config = function(opts, spec)
      local nvim_metals_group = vim.api.nvim_create_augroup("nvim_metals", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = spec.ft,
        callback = function()
          require("metals")
            .setup({
              metals_ignore_build_tools = { "sbt", "mill" },
              metals_experimental_features = true,
              metals_use_bloop = true,
              metals_use_mill = false,
              metals_use_sbt = true,
              metals_use_coursier = true,
              metals_use_ammonite = false,
              metals_use_scalafix = true,
              metals_use_scalafmt = true,
              metals_use_scala3 = true,
              metals_use_sbt_script = true,
              metals_use_bloop_script = true,
              metals_use_coursier_script = true,
              metals_use_scala_cli = true,
              metals_use_jdi = true,
              metals_use_javac = true,
              metals_use_scalac = true,
              metals_use_scala_doc = true,
              metals_use_scala_interactive = true,
              metals_use_scala_library = true,
              metals_use_scala_reflect = true,
              metals_use_scala_compiler = true,
            })
            .initialize_or_attach(opts)
        end,
        group = nvim_metals_group,
      })
    end,
  },
  -- {
  --   "Exafunction/windsurf.nvim",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "hrsh7th/nvim-cmp",
  --   },
  --   config = function()
  --     require("codeium").setup({})
  --   end,
  -- },
}
