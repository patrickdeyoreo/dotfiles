return {
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    opts = {
      -- preset = "classic",
      --transparent_bg = false,
      transparent_bg = true,
      options = {
        -- Settings for multiline diagnostics
        multilines = {
          enabled = true, -- Enable support for multiline diagnostic messages
          -- always_show = false,       -- Always show messages on all lines of multiline diagnostics
          -- trim_whitespaces = false,  -- Remove leading/trailing whitespace from each line
          -- tabstop = 4,               -- Number of spaces per tab when expanding tabs
          -- severity = nil,            -- Filter multiline diagnostics by severity (e.g., { vim.diagnostic.severity.ERROR })
        },
        add_messages = {
          display_count = true,
          show_multiple_glyphs = false, -- One icon per distinct severity on the line, not one per diagnostic
        },
        -- Only show source if multiple sources exist for the same diagnostic
        show_source = { enabled = true, if_many = true },
        -- Throttle update frequency in milliseconds to improve performance
        -- Higher values reduce CPU usage but may feel less responsive
        -- Set to 0 for immediate updates (may cause lag on slow systems)
        throttle = 20,
      },
      signs = {
        left = " ",
        right = " ",
        diag = "󱨧", --  󱨧 ✦ ✧ ✱ ⛤ ⛧ ✹ ✸ ✶   󰎂 󰎃
        arrow = "", --  󰩔 󱖚 󰬩 󰧙 󰳞     󰧀
        up_arrow = "󰩕", --  ↑ 󰩕 󱖗 󰧇      󰛃 󰜸 
        vertical = " │", --  │ ┆ ┊ ╎ 󰇙
        vertical_end = " ╰", --  ╰ └ ┗ ╚
      },
      blend = {
        factor = 0.28,
      },
    },
    config = function(_, opts)
      local tid = require("tiny-inline-diagnostic")
      tid.setup(opts)
      vim.diagnostic.config({ virtual_text = false })
    end,
  },
  {
    "folke/todo-comments.nvim",
    cond = vim.g.vscode == nil,
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next TODO comment",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Previous TODO comment",
      },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "TODOs (Trouble)" },
      { "<leader>xT", "<cmd>Trouble todo toggle filter={tag={TODO,FIX,FIXME}}<cr>", desc = "TODO/FIX/FIXME (Trouble)" },
    },
  },
  {
    "mfussenegger/nvim-lint",
    cond = vim.g.vscode == nil,
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        bash = { "shellcheck" },
        dockerfile = { "hadolint" },
        go = { "golangcilint" },
        javascript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        markdown = { "markdownlint" },
        python = { "ruff" },
        sh = { "shellcheck" },
        terraform = { "tflint" },
        typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        yaml = { "yamllint" },
        zsh = { "zsh" },
      }
      -- tflint and golangcilint re-scan the whole module/package on every invocation
      -- (multi-second, CPU-bound), unlike the other linters here which are fast,
      -- single-file tools. Running them on InsertLeave respawns that scan every time
      -- you leave insert mode, which is what makes editing large codebases feel slow.
      -- Keep them on save/read only; other filetypes still get the responsive
      -- InsertLeave lint.
      local slow_linters = { tflint = true, golangcilint = true }

      local function fast_linters_for(ft)
        local names = {}
        for _, name in ipairs(lint.linters_by_ft[ft] or {}) do
          if not slow_linters[name] then
            table.insert(names, name)
          end
        end
        return names
      end

      local group = vim.api.nvim_create_augroup("nvim-lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        group = group,
        callback = function()
          if vim.bo.buftype == "" then
            lint.try_lint()
          end
        end,
      })

      vim.api.nvim_create_autocmd("InsertLeave", {
        group = group,
        callback = function()
          if vim.bo.buftype == "" then
            lint.try_lint(fast_linters_for(vim.bo.filetype))
          end
        end,
      })
    end,
  },
  {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>x-",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>xS",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xl",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
    specs = {
      "folke/snacks.nvim",
      cond = vim.g.vscode == nil,
      opts = function(_, opts)
        return vim.tbl_deep_extend("force", opts or {}, {
          picker = {
            actions = require("trouble.sources.snacks").actions,
            win = {
              input = {
                keys = {
                  ["<c-t>"] = {
                    "trouble_open",
                    mode = { "n", "i" },
                  },
                },
              },
            },
          },
        })
      end,
    },
  },
}
