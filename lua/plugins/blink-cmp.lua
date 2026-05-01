return {
  "blink.cmp",
  event = "BufEnter",
  after = function()
    require("lz.n").trigger_load("blink-ripgrep.nvim")
    require("lz.n").trigger_load("blink.compat")
    require("blink.cmp").setup({
      cmdline = { enabled = true, completion = { menu = { auto_show = true } } },
      appearance = { nerd_font_variant = "normal", use_nvim_cmp_as_default = true },
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
          treesitter_highlighting = true,
          update_delay_ms = 50,
          window = { border = "rounded" },
        },
        menu = {
          border = "rounded",
          draw = {
            columns = { { "kind_icon", "kind" }, { "label", "label_description", gap = 2 } },
            treesitter = {
              "lsp",
            },
          },
        },
      },
      fuzzy = { prebuilt_binaries = { download = false } },
      keymap = {
        ["<C-g>"] = {
          function()
            require("blink-cmp").show({ providers = { "ripgrep" } })
          end,
        },
        ["<C-j>"] = { "snippet_backward", "fallback" },
        ["<C-k>"] = { "snippet_forward", "fallback" },
        ["<S-Tab>"] = {},
        ["<Tab>"] = {},
        preset = "default",
      },
      signature = { enabled = true, window = { border = "rounded" } },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = {
          lua = { "lazydev", "lsp", "path", "snippets", "buffer" },
        },
        providers = {
          lazydev = { module = "lazydev.integrations.blink", name = "LazyDev", score_offset = 100 },
          markdown = { module = "render-markdown.integ.blink", name = "RenderMarkdown" },
          ripgrep = { module = "blink-ripgrep", name = "Ripgrep" },
          snippets = { opts = { friendly_snippets = true } },
        },
      },
    })
  end,
}
