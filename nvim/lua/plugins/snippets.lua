return {
  {
    'L3MON4D3/LuaSnip',
    -- Follow latest release.
    version = 'v2.*',
    -- Match blink.cmp's own lazy-load trigger (its only consumer here)
    event = { "InsertEnter", "CmdlineEnter" },
    -- Install jsregexp (optional!)
    build = 'make install_jsregexp',
    dependencies = {
      'rafamadriz/friendly-snippets',
    },
    opts = {},
    config = function (_, opts)
      require('luasnip').setup(opts)
      require('luasnip.loaders.from_vscode').lazy_load()
    end,
  },
}
