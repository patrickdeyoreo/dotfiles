return {
  {
    'nvim-mini/mini.icons',
    version = '*',
    lazy = true,
    opts = {},
    config = function (_, opts)
      require('mini.icons').setup(opts)
      require('mini.icons').mock_nvim_web_devicons()
    end
  },
  {
    'nvim-mini/mini.comment',
    version = '*',
    cond = true,
    keys = {
      -- 'o' mode covers the <leader>c textobject (e.g. d<leader>c); 'n'/'x' cover toggle/comment_visual
      { "<leader>c", mode = { "n", "x", "o" }, desc = "Comment (toggle / textobject)" },
      { "<leader>cc", mode = "n", desc = "Toggle comment line" },
    },
    opts = {
      -- Options which control module behavior
      options = {
        -- Function to compute custom 'commentstring' (optional)
        -- custom_commentstring = nil,

        -- Whether to ignore blank lines when commenting
        -- ignore_blank_line = false,

        -- Whether to ignore blank lines in actions and textobject
        -- start_of_line = false,

        -- Whether to force single space inner padding for comment parts
        -- pad_comment_parts = true,
      },
      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        -- Toggle comment (like `gcip` - comment inner paragraph) for both
        -- Normal and Visual modes
        comment = '<leader>c',

        -- Toggle comment on current line
        comment_line = '<leader>cc',

        -- Toggle comment on visual selection
        comment_visual = '<leader>c',

        -- Define 'comment' textobject (like `dgc` - delete whole comment block)
        -- Works also in Visual mode if mapping differs from `comment_visual`
        textobject = '<leader>c',
      },
      -- Hook functions to be executed at certain stage of commenting
      hooks = {
        -- Before successful commenting. Does nothing by default.
        -- pre = function() end,

        -- After successful commenting. Does nothing by default.
        -- post = function() end,
      },
    }
  },
}
