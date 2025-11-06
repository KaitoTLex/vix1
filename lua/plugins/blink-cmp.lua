return {
  "blink.cmp",
  event = "BufEnter",
  after = function()
    require("lz.n").trigger_load("blink-ripgrep")
    require("lz.n").trigger_load("blink.compat")

    require("blink.cmp").setup({
      keymap = {
        preset = "default",
        ["<Tab>"] = {},
        ["<S-Tab>"] = {},
        ["<C-g>"] = {
          function()
            require("blink-cmp").show({ providers = { "ripgrep" } })
          end,
        },
        ["<C-k>"] = { "snippet_forward", "fallback" },
        ["<C-j>"] = { "snippet_backward", "fallback" },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "normal",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = {
          lua = { "lazydev", "lsp", "path", "snippets", "buffer" },
          markdown = { "lsp", "snippets", "obsidian", "obsidian_new", "obsidian_tags", "path", "buffer", "markdown" },
          org = { "orgmode" },
        },
        providers = {
          ripgrep = {
            module = "blink-ripgrep",
            name = "Ripgrep",
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
          markdown = { name = "RenderMarkdown", module = "render-markdown.integ.blink" },
          obsidian = {
            name = "obsidian",
            module = "blink.compat.source",
          },
          obsidian_new = {
            name = "obsidian_new",
            module = "blink.compat.source",
          },
          obsidian_tags = {
            name = "obsidian_tags",
            module = "blink.compat.source",
          },
          orgmode = {
            name = "orgmode",
            -- module = "blink.compat.source",
            module = "orgmode.org.autocompletion.blink",
            fallbacks = { "buffer" },
          },
        },
      },
      completion = {
        menu = {
          border = "rounded",
          draw = {
            columns = {
              { "kind_icon", "kind" },
              { "label", "label_description", gap = 2 },
            },
            treesitter = { "lsp" },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
          update_delay_ms = 50,
          treesitter_highlighting = true,
          window = { border = "rounded" },
        },
      },
      signature = {
        window = { border = "rounded" },
        enabled = true,
      },
      fuzzy = { prebuilt_binaries = { download = false } },
    })
  end,
}
