-- Shared by the <C-Tab>/<S-Tab>/<Tab> keymap chains below: `require` on an
-- already-loaded module is cheap, but repeating the same pcall+nil-check in
-- four places invites drift. `get_copilot_nes` also folds in copilot-lsp's
-- own "is anything pending" check (vim.b.nes_state) so callers can just test
-- truthiness instead of re-deriving it.
local function get_copilot_suggestion()
  local ok, sug = pcall(require, "copilot.suggestion")
  return ok and sug or nil
end

local function get_copilot_nes()
  if not vim.b.nes_state then
    return nil
  end
  local ok, nes_api = pcall(require, "copilot.nes.api")
  return ok and nes_api or nil
end

return {
  {
    "saghen/blink.cmp",
    -- Pin to v1 and use the prebuilt Rust fuzzy matcher (no local build needed).
    -- v2 is mid-flight with breaking changes; revisit once it stabilizes.
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "L3MON4D3/LuaSnip", -- snippet engine (preset = "luasnip")
      "rafamadriz/friendly-snippets",
      "Kaiser-Yang/blink-cmp-avante", -- avante @mention / / command completion
      "Kaiser-Yang/blink-cmp-git", -- native git/github commit/issue/PR/mention source
      "nvim-mini/mini.icons", -- kind icons in the menu
      -- lazydev.nvim and ecolog.nvim ship their own native blink providers.
      -- codecompanion.nvim self-registers its blink source on setup.
    },
    opts = {
      snippets = { preset = "luasnip" },
      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "normal",
      },
      keymap = {
        -- Start from the sane default preset (C-n/C-p/arrows select, C-y accept,
        -- C-e hide, C-space show) and override the keys we care about.
        preset = "default",
        ["<C-q>"] = { "hide", "fallback" },
        ["<C-@>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        ["<PageUp>"] = { "scroll_documentation_up", "fallback" },
        ["<PageDown>"] = { "scroll_documentation_down", "fallback" },
        ["<C-g>"] = { "show_documentation", "hide_documentation" },
        -- Leave <C-k> to the LSP signature-help mapping set in lsp.lua.
        ["<C-k>"] = { "fallback" },
        -- Confirm only when an entry is actively selected (selection.preselect = false),
        -- otherwise fall through to a literal <CR>. Mirrors the old nvim-cmp behavior.
        ["<CR>"] = { "accept", "fallback" },
        ["<Esc>"] = { "cancel", "fallback" }, -- close the blink menu (revert preview) and stay in insert; falls through to normal Esc otherwise
        ["<C-Tab>"] = {
          -- Escape hatch: dismiss blink's menu, a copilot ghost suggestion, and any
          -- pending NES edit, then insert a real (expandtab-respecting) tab -- bypasses
          -- the smart <Tab> chain entirely. Needs a terminal that can distinguish
          -- Ctrl-Tab from plain Tab (Kitty protocol); degrades to plain <Tab> otherwise.
          function(cmp)
            if cmp.is_visible() then
              cmp.hide()
            end
            local sug = get_copilot_suggestion()
            if sug and sug.is_visible() then
              sug.dismiss()
            end
            local nes_api = get_copilot_nes()
            if nes_api then
              nes_api.nes_clear()
            end
            return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
          end,
        },
        ["<Tab>"] = {
          -- 1. navigate the menu when it is open (both blink and a copilot
          --    suggestion can be visible at once, but blink wins while it's open)
          function(cmp)
            if cmp.is_visible() then
              return cmp.select_next()
            end
          end,
          -- 2. accept a Copilot ghost suggestion once blink is closed
          function()
            local sug = get_copilot_suggestion()
            if sug and sug.is_visible() then
              sug.accept()
              -- copilot clears the ghost-text extmark synchronously but defers the
              -- actual multi-line insert to the next tick (vim.schedule_wrap); forcing
              -- one redraw after that settles lets everything (treesitter reparse,
              -- diagnostics, etc.) catch up in a single pass instead of trickling.
              vim.schedule(function()
                vim.cmd("redraw")
              end)
              return true
            end
          end,
          -- 3. jump forward in an active snippet
          "snippet_forward",
          -- 3. only trigger completion when the prefix is non-whitespace,
          --    otherwise emit a literal <Tab> (indent)
          function(cmp)
            local col = vim.fn.col(".") - 1
            local line = vim.api.nvim_get_current_line()
            if col == 0 or line:sub(col, col):match("%s") then
              return false -- fall through to <Tab>
            end
            return cmp.show()
          end,
          "fallback",
        },
        ["<S-Tab>"] = {
          -- Accept a pending NES (Next Edit Suggestion) -- a predicted multi-line
          -- change/delete elsewhere in the buffer -- when blink's menu is closed
          -- (standard select_prev cycling still applies when it's open). copilot-lsp
          -- only ever registers its accept keymap in normal mode (hardcoded), so this
          -- is what makes it reachable from insert mode. Lives here rather than
          -- <M-Tab>: most window managers grab Alt-Tab before it reaches the terminal.
          function(cmp)
            if cmp.is_visible() then
              return
            end
            local nes_api = get_copilot_nes()
            if not nes_api then
              return
            end
            local applied = nes_api.nes_apply_pending_nes()
            if applied then
              nes_api.nes_walk_cursor_end_edit()
            end
            return applied
          end,
          "select_prev",
          "fallback",
        },
      },
      completion = {
        keyword = { range = "full" },
        -- Don't preselect; auto-insert the text of the highlighted item as you navigate.
        list = { selection = { preselect = false, auto_insert = true } },
        -- Semantic auto-brackets on accept (replaces the old nvim-autopairs
        -- on_confirm_done hook, which has no blink equivalent).
        accept = { auto_brackets = { enabled = true } },
        -- Copilot owns inline ghost text; keep blink's off to avoid two producers.
        ghost_text = { enabled = false },
        menu = {
          border = "rounded",
          scrollbar = false,
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
          draw = {
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "kind" },
            },
            components = {
              kind_icon = {
                ellipsis = false,
                text = function(ctx)
                  local icon = MiniIcons.get("lsp", ctx.kind)
                  return " " .. (icon or "") .. " "
                end,
                highlight = function(ctx)
                  local _, hl = MiniIcons.get("lsp", ctx.kind)
                  return hl
                end,
              },
              kind = {
                ellipsis = false,
                text = function(ctx)
                  return "    (" .. ctx.kind .. ")"
                end,
                highlight = "BlinkCmpKind",
              },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "rounded" },
        },
      },
      signature = {
        enabled = true,
        window = { border = "rounded" },
      },
      sources = {
        -- Priority is expressed via score_offset (was nvim-cmp's grouped sources).
        default = { "avante", "lazydev", "lsp", "ecolog", "path", "snippets", "buffer" },
        -- git/github only in commit-style buffers, on top of the defaults.
        per_filetype = {
          gitcommit = { inherit_defaults = true, "git" },
          NeogitCommitMessage = { inherit_defaults = true, "git" },
          octo = { inherit_defaults = true, "git" },
        },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
          avante = {
            name = "Avante",
            module = "blink-cmp-avante",
            score_offset = 90,
          },
          ecolog = {
            name = "ecolog",
            module = "ecolog.integrations.cmp.blink_cmp",
            score_offset = 50,
          },
          git = {
            name = "git",
            module = "blink-cmp-git",
            score_offset = 40,
          },
          buffer = { score_offset = -10 },
        },
      },
      cmdline = {
        enabled = true,
        keymap = { preset = "cmdline" },
        completion = {
          menu = { auto_show = true },
          list = { selection = { preselect = false, auto_insert = true } },
        },
        -- `:`  -> command + path ; `/` `?` -> buffer (the old nvim_lsp_document_symbol
        -- cmdline source has no blink equivalent and is dropped).
        sources = function()
          local t = vim.fn.getcmdtype()
          if t == ":" or t == "@" then
            return { "cmdline", "path" }
          end
          if t == "/" or t == "?" then
            return { "buffer" }
          end
          return {}
        end,
      },
    },
    opts_extend = { "sources.default" },
  },
}
