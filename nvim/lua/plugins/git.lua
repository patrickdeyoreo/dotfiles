return {
  {
    'akinsho/git-conflict.nvim',
    version = "*",
    config = true,
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "▁" },
        topdelete    = { text = "▔" },
        changedelete = { text = "▎" },
        untracked    = { text = "▎" },
      },
      signs_staged = {
        add          = { text = "▍" },
        change       = { text = "▍" },
        delete       = { text = "▁" },
        topdelete    = { text = "▔" },
        changedelete = { text = "▍" },
      },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
        end
        map("n", "]h", function() gs.nav_hunk("next") end, "Next git hunk")
        map("n", "[h", function() gs.nav_hunk("prev") end, "Previous git hunk")
        map("n", "]H", function() gs.nav_hunk("last") end, "Last git hunk")
        map("n", "[H", function() gs.nav_hunk("first") end, "First git hunk")
        map({ "n", "v" }, "<leader>gs", gs.stage_hunk, "Stage hunk")
        map({ "n", "v" }, "<leader>gr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
        map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
        map("n", "<leader>gu", gs.undo_stage_hunk, "Undo stage hunk")
        map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle line blame")
        map("n", "<leader>gd", gs.diffthis, "Diff this")
        map("n", "<leader>gD", function() gs.diffthis("~") end, "Diff against HEAD~1")
        map({ "o", "x" }, "ih", gs.select_hunk, "Select git hunk")
      end,
    },
  },
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",         -- required
      "sindrets/diffview.nvim",        -- optional - Diff integration

      -- Only one of these is needed.
      "ibhagwan/fzf-lua",              -- optional
      --"nvim-mini/mini.pick",         -- optional
      --"folke/snacks.nvim",           -- optional
    },
    opts = {
      graph_style = "unicode",
      highlight = {
        italic = true,
        bold = true,
        underline = true
      },
      -- Disabling `auto_refresh` will make it so you have to manually refresh the status after you open it.
      auto_refresh = true,
      -- Change the default way of opening neogit
      kind = "tab",
      -- Floating window style 
      floating = {
        relative = "editor",
        width = 0.85,
        height = 0.70,
        style = "minimal",
        border = "rounded",
      },
      -- Disable line numbers
      disable_line_numbers = true,
      -- Disable relative line numbers
      disable_relative_line_numbers = true,
      -- The time after which an output console is shown for slow running commands
      console_timeout = 2500,
      -- Automatically show console if a command takes more than console_timeout milliseconds
      auto_show_console = true,
      -- Automatically close the console if the process exits with a 0 (success) status
      auto_close_console = true,
    },
  },
}
