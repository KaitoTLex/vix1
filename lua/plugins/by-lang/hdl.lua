return {
  "verilog_systemverilog.vim",
  ft = { "vhdl", "systemverilog", "verilog" },
  after = function()
    vim.g.verilog_syntax_fold_lst = "all"

    local function setup_hdl_buf(ev)
      vim.opt_local.foldmethod = "syntax"
      vim.opt_local.foldlevel = 99

      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
      end

      -- verilog_systemverilog.vim navigation
      map("n", "<leader>hf", ":VerilogFollowInstance<CR>", "Follow instance to module")
      map("n", "<leader>hF", ":VerilogFollowPort<CR>", "Follow port")
      map("n", "<leader>hi", ":VerilogGotoInstanceStart<CR>", "Go to instance start")
      map("n", "<leader>he", ":VerilogErrorJump<CR>", "Jump to lint error")

      -- simulation / synthesis runners (override per project via .nvim.lua / exrc)
      map("n", "<leader>hr", function()
        vim.cmd("botright split | terminal make sim")
      end, "Run simulation")
      map("n", "<leader>hb", function()
        vim.cmd("botright split | terminal make")
      end, "Build / synthesize")
    end

    -- apply to any future HDL buffers
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "vhdl", "systemverilog", "verilog" },
      callback = setup_hdl_buf,
    })

    -- apply to the buffer that triggered lz.n to load this plugin
    if vim.tbl_contains({ "vhdl", "systemverilog", "verilog" }, vim.bo.filetype) then
      setup_hdl_buf({ buf = vim.api.nvim_get_current_buf() })
    end
  end,
}
