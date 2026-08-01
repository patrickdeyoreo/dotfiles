return {
  {
    "kylechui/nvim-surround",
    cond = true,
    version = "^3.0.0", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end
  },
  {
    'Wansmer/treesj',
    cond = true,
    dependencies = {
      -- if you install parsers with `nvim-treesitter`
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      use_default_keymaps = false,
    },
    keys = {
      { "<Space>t", function() require('treesj').toggle() end, desc = "Toggle split/join (treesj)" },
      { "<Space>T", function() require('treesj').toggle({ split = { recursive = true } }) end, desc = "Toggle split/join recursive (treesj)" },
      { "<Space>s", function() require('treesj').split() end, desc = "Split (treesj)" },
      { "<Space>j", function() require('treesj').join() end, desc = "Join (treesj)" },
    },
    config = function (_, opts)
      require('treesj').setup(opts)
    end
  },
  {
    "https://codeberg.org/andyg/leap.nvim",
    cond = false,
    version = false,
    opts = {
      preview_filter = function (ch0, ch1, ch2)
        return not (
          ch1:match('%s') or
          ch0:match('%a') and ch1:match('%a') and ch2:match('%a')
        )
      end,
    },
    config = function (_, opts)
      require("leap").setup(opts)
      require('leap.user').set_repeat_keys(
   '<enter>', '<backspace>'
      )
      vim.keymap.set(
        {'n', 'x', 'o'}, 's', '<Plug>(leap)'
      )
      vim.keymap.set(
        {'n'}, 'S', '<Plug>(leap-from-window)'
      )
      vim.api.nvim_set_hl(
        0, 'LeapBackdrop', { link = 'Comment' }
      )
    end,
  },
  -- conform.nvim is configured in formatting.lua; grug-far in search.lua
  {
    'windwp/nvim-autopairs',
    cond = true,
    event = "InsertEnter",
    opts = {
      fast_wrap = {
        chars = { '{', '[', '(', '"', "'" },
        disable_filetype = { "TelescopePrompt" , "guihua", "guihua_rust", "clap_input" },
        pattern = [=[[%'%"%>%]%)%}%,]]=],
        end_key = '$',
        before_key = 'h',
        after_key = 'l',
        cursor_pos_before = true,
        keys = 'qwertyuiopzxcvbnmasdfghjkl',
        manual_position = true,
        highlight = 'Search',
        highlight_grey='Comment',
      },
    },
  },
}
