local function lualine_opts()
      local utils = require("core.utils")
      -- Highlight group names, resolved at render time so the colors track
      -- the active colorscheme across the F11/F12/F24 rotation.
      -- copilot.lua's statusNotification.status type is ''|'Normal'|'InProgress'|'Warning'
      -- (copilot/status/init.lua) -- 'Error' is never actually produced, verified directly.
      local copilot_colors = {
        [""] = "Comment",
        ["Normal"] = "Comment",
        ["InProgress"] = "DiagnosticInfo",
        ["Warning"] = "DiagnosticWarn",
      }
      local filetype_map = {
        lazy = { name = "lazy.nvim", icon = "󰒲 " },
        mason = { name = "mason", icon = "󱌣 " },
        snacks_picker_input = { name = "picker", icon = "󰩕 " },
        ["Avante"] = { name = "avante", icon = " " },
      }
      return {
        options = {
          component_separators = { left = " ", right = " " },
          section_separators = { left = " ", right = " " },
          theme = "auto",
          globalstatus = true,
          disabled_filetypes = { statusline = { "alpha" } },
        },
        sections = {
          lualine_a = {
            {
              "mode",
              icon = "",
              fmt = function(mode)
                return mode:lower()
              end,
            },
          },
          lualine_b = {
            { "branch", icon = "" },
            {
              function()
                return "recording @" .. vim.fn.reg_recording()
              end,
              cond = function()
                return vim.fn.reg_recording() ~= ""
              end,
              color = { fg = "#f24bb0" },
            },
          },
          lualine_c = {
            {
              "diagnostics",
              symbols = {
                error = " ",
                warn = " ",
                info = " ",
                hint = "󱐌 ",
              },
            },
            {
              function()
                local ft = vim.bo.filetype
                if filetype_map[ft] then
                  return " " .. filetype_map[ft].icon
                end
                local devicons = require("nvim-web-devicons")
                local icon = devicons.get_icon(vim.fn.expand("%:t")) or devicons.get_icon_by_filetype(ft) or " 󰈤"
                return icon .. " "
              end,
              color = function()
                local _, hl = require("nvim-web-devicons").get_icon(vim.fn.expand("%:t"))
                if hl then
                  return hl
                end
                return utils.get_hlgroup("Normal")
              end,
              separator = "",
              padding = { left = 0, right = 0 },
            },
            {
              "filename",
              padding = { left = 0, right = 0 },
              fmt = function(name)
                if filetype_map[vim.bo.filetype] then
                  return filetype_map[vim.bo.filetype].name
                else
                  return name
                end
              end,
            },
            {
              function()
                local buffer_count = require("core.utils").get_buffer_count()

                return "+" .. buffer_count - 1 .. " "
              end,
              cond = function()
                return require("core.utils").get_buffer_count() > 1
              end,
              color = function()
                return utils.get_hlgroup("Operator")
              end,
              padding = { left = 0, right = 1 },
            },
            {
              function()
                local tab_count = vim.fn.tabpagenr("$")
                if tab_count > 1 then
                  return vim.fn.tabpagenr() .. " of " .. tab_count
                end
              end,
              cond = function()
                return vim.fn.tabpagenr("$") > 1
              end,
              icon = "󰓩",
              color = function()
                return utils.get_hlgroup("Special")
              end,
            },
            {
              function()
                return require("nvim-navic").get_location()
              end,
              cond = function()
                return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
              end,
              color = function()
                return utils.get_hlgroup("Comment")
              end,
            },
          },
          lualine_x = {
            (function()
              -- ecolog.integrations.statusline.lualine() returns a lualine
              -- Component class table; pass it through directly. The pcall
              -- + class form keeps lualine happy if ecolog isn't installed.
              local ok, mod = pcall(require, "ecolog.integrations.statusline")
              if ok then
                return mod.lualine()
              end
              return {
                function()
                  return ""
                end,
                cond = function()
                  return false
                end,
              }
            end)(),
            {
              require("lazy.status").updates,
              cond = require("lazy.status").has_updates,
              color = function()
                return utils.get_hlgroup("String")
              end,
            },
            {
              function()
                local icon = " "
                local status = require("copilot.status").data
                return icon .. (status.message or "")
              end,
              cond = function()
                local ok, clients = pcall(vim.lsp.get_clients, { name = "copilot", bufnr = 0 })
                return ok and #clients > 0
              end,
              color = function()
                if not package.loaded["copilot"] then
                  return
                end
                local status = require("copilot.status").data
                return utils.get_hlgroup(copilot_colors[status.status] or copilot_colors[""])
              end,
            },
            {
              "diff",
            },
          },
          lualine_y = {
            {
              function()
                local ok, result = pcall(vim.fn.searchcount, { maxcount = 999 })
                if not ok or result.total == 0 then
                  return ""
                end
                return result.current .. "/" .. result.total
              end,
              cond = function()
                return vim.v.hlsearch == 1
              end,
              icon = " ",
              color = function()
                return utils.get_hlgroup("String")
              end,
            },
            {
              "progress",
            },
            {
              "location",
              color = function()
                return utils.get_hlgroup("Boolean")
              end,
            },
          },
          lualine_z = {
            {
              "datetime",
              style = "  %X",
            },
          },
        },
      }
end

return {
  {
    "nvim-lualine/lualine.nvim",
    cond = vim.g.vscode == nil,
    event = "VeryLazy",
    dependencies = {
      "nvim-mini/mini.icons", -- config lives in mini.lua; this just orders load-before-lualine
      "folke/noice.nvim",
    },
    opts = lualine_opts,
    config = function(_, opts)
      require("lualine").setup(opts)
      -- ecolog.nvim lazy-loads via `keys` (env.lua), so it's virtually never
      -- loaded yet when lualine_opts() first runs -- its statusline component
      -- would otherwise permanently bake in as a no-op. Rebuild once ecolog
      -- actually loads so the real component gets picked up.
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyLoad",
        callback = function(event)
          if event.data == "ecolog.nvim" then
            require("lualine").setup(lualine_opts())
          end
        end,
      })
    end,
  },
  {
    "akinsho/bufferline.nvim",
    cond = vim.g.vscode == nil,
    -- Safe to defer: always_show_bufferline=false already means it draws nothing
    -- until a 2nd buffer exists, regardless of when it loads.
    event = "VeryLazy",
    version = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      options = {
        themable = true,
        color_icons = true,
        show_buffer_icons = true,
        -- stylua: ignore
        -- close_command = function(n) Snacks.bufdelete(n) end,
        -- stylua: ignore
        -- right_mouse_command = function(n) Snacks.bufdelete(n) end,
        always_show_bufferline = false,
        diagnostics = "nvim_lsp",
        --- count is an integer representing total count of errors
        --- level is a string "error" | "warning"
        --- this should return a string
        --- Don't get too fancy as this function will be executed a lot
        diagnostics_indicator = function(count, level)
          local symbol = level:match("error") and " "
            or level:match("warning") and " "
            or level:match("info") and " "
            or ""
          return " " .. symbol .. count
        end,
      },
    },
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    cond = vim.g.vscode == nil,
    -- NOT "VeryLazy": ibl's own catch-up for already-open buffers is a VimEnter
    -- autocmd (ibl/autocmds.lua), and VeryLazy fires *after* VimEnter -- it would
    -- miss that and guides wouldn't show on the first buffer until some other
    -- event (CursorMoved etc.) happens to fire. BufReadPost/BufNewFile get
    -- remapped by lazy.nvim to the earlier BufReadPre internally (see
    -- lazy/core/handler/event.lua), so ibl loads in time to catch its own
    -- VimEnter listener before VimEnter actually fires.
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "HiPhish/rainbow-delimiters.nvim",
    },
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    opts = {
      indent = {
        char = "▏",
        highlight = {
          "RainbowDelimiterOrange",
          "RainbowDelimiterYellow",
          "RainbowDelimiterGreen",
          "RainbowDelimiterViolet",
          "RainbowDelimiterCyan",
          "RainbowDelimiterBlue",
        },
      },
      scope = {
        enabled = true,
        show_start = true,
        show_end = true,
        highlight = {
          "RainbowDelimiterOrange",
          "RainbowDelimiterYellow",
          "RainbowDelimiterGreen",
          "RainbowDelimiterViolet",
          "RainbowDelimiterCyan",
          "RainbowDelimiterBlue",
        },
      },
      whitespace = {
        remove_blankline_trail = true,
      },
      exclude = {
        filetypes = {
          "lspinfo",
          "packer",
          "checkhealth",
          "help",
          "man",
          "gitcommit",
          "TelescopePrompt",
          "TelescopeResults",
          "",
        },
        buftypes = {
          "nofile",
          "terminal",
          "quickfix",
          "prompt",
        },
      },
    },
    config = function(_, opts)
      require("ibl").setup(opts)
      local hooks = require("ibl.hooks")
      hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
    end,
  },
  {
    "HiPhish/rainbow-delimiters.nvim",
    cond = vim.g.vscode == nil,
    -- Same reasoning as indent-blankline: it attaches via a `FileType` autocmd in
    -- its own plugin/rainbow-delimiters.lua, no VimEnter-based catch-up. FileType
    -- gets remapped to the even-earlier BufReadPost internally by lazy.nvim, so
    -- this loads in time to attach to the first buffer's FileType event.
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      strategy = {
        [""] = "rainbow-delimiters.strategy.global",
      },
      query = {
        [""] = "rainbow-delimiters",
        lua = "rainbow-blocks",
      },
      priority = {
        [""] = 110,
        lua = 210,
      },
      highlight = {
        "RainbowDelimiterOrange",
        "RainbowDelimiterYellow",
        "RainbowDelimiterGreen",
        "RainbowDelimiterViolet",
        "RainbowDelimiterCyan",
        "RainbowDelimiterBlue",
      },
      blacklist = { "c", "cpp" },
    },
    config = function(_, opts)
      require("rainbow-delimiters.setup").setup(opts)

      -- The plugin ships gruvbox-muted defaults (its "Cyan" is #a89984, a tan
      -- that barely reads as a distinct color). Override with a vivid palette
      -- and re-apply on every colorscheme change so rainbow indent guides stay
      -- visible across the F11/F12/F24 rotation.
      local palette = {
        RainbowDelimiterRed = "#f24bb0",
        RainbowDelimiterOrange = "#fab387",
        RainbowDelimiterYellow = "#f9e2af",
        RainbowDelimiterGreen = "#a6e3a1",
        RainbowDelimiterCyan = "#94e2d5",
        RainbowDelimiterBlue = "#89b4fa",
        RainbowDelimiterViolet = "#cba6f7",
      }
      local apply = function()
        for name, fg in pairs(palette) do
          vim.api.nvim_set_hl(0, name, { fg = fg })
        end
      end
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("rainbow-delimiter-palette", { clear = true }),
        callback = apply,
      })
      apply()
    end,
  },
  {
    "kevinhwang91/nvim-bqf",
    cond = vim.g.vscode == nil,
    ft = "qf",
    opts = {},
  },
  {
    "RRethy/vim-illuminate",
    cond = vim.g.vscode == nil,
    event = { "BufReadPost", "BufNewFile" },
    -- Defaults are right (lsp > treesitter > regex providers). The options
    -- previously set here (bind/handler_opts/hint_prefix) belonged to
    -- lsp_signature.nvim and were silently ignored.
    opts = {},
    config = function(_, opts)
      require("illuminate").configure(opts)
    end,
  },
  {
    "goolord/alpha-nvim",
    cond = vim.g.vscode == nil,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      local function greeting()
        local hour = tonumber(os.date("%H"))
        local period
        if hour >= 5 and hour < 12 then
          period = "morning"
        elseif hour >= 12 and hour < 17 then
          period = "afternoon"
        elseif hour >= 17 and hour < 21 then
          period = "evening"
        else
          period = "night"
        end
        return "✧ good " .. period .. ", " .. (vim.env.USER or "traveler") .. " ✧"
      end

      local stars = {
        type = "text",
        val = "✧                               ✧",
        opts = { position = "center", hl = "Special" },
      }

      local art = {
        type = "text",
        val = {
          [[███╗   ██╗██╗   ██╗██╗███╗   ███╗]],
          [[████╗  ██║██║   ██║██║████╗ ████║]],
          [[██╔██╗ ██║██║   ██║██║██╔████╔██║]],
          [[██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║]],
          [[██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║]],
          [[╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝]],
        },
        opts = { position = "center", hl = "Function" },
      }

      local greet = {
        type = "text",
        val = greeting(),
        opts = { position = "center", hl = "Comment" },
      }

      dashboard.section.buttons.val = {
        dashboard.button("n", "✧  New file", "<cmd>ene<cr>"),
        dashboard.button("f", "  Find file", "<cmd>FzfLua files<cr>"),
        dashboard.button("g", "  Find text", "<cmd>FzfLua live_grep<cr>"),
        dashboard.button("r", "  Recent files", "<cmd>FzfLua oldfiles<cr>"),
        dashboard.button("s", "  Git status", "<cmd>FzfLua git_status<cr>"),
        dashboard.button("c", "  Config", "<cmd>e " .. vim.fn.stdpath("config") .. "/init.lua<cr>"),
        dashboard.button("l", "󰒲  Lazy", "<cmd>Lazy<cr>"),
        dashboard.button("m", "  Mason", "<cmd>Mason<cr>"),
        dashboard.button("q", "  Quit", "<cmd>qa<cr>"),
      }

      dashboard.section.footer.opts.hl = "Comment"

      dashboard.config.layout = {
        { type = "padding", val = 2 },
        stars,
        { type = "padding", val = 1 },
        art,
        { type = "padding", val = 1 },
        stars,
        { type = "padding", val = 1 },
        greet,
        { type = "padding", val = 2 },
        dashboard.section.buttons,
        { type = "padding", val = 1 },
        dashboard.section.footer,
      }

      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimStarted",
        once = true,
        callback = function()
          local stats = require("lazy").stats()
          local cs = vim.g.colors_name or "default"
          dashboard.section.footer.val = "✧ "
            .. stats.loaded
            .. "/"
            .. stats.count
            .. " plugins"
            .. " · "
            .. string.format("%.0f", stats.startuptime)
            .. "ms"
            .. " · "
            .. cs
          pcall(vim.cmd.AlphaRedraw)
        end,
      })

      alpha.setup(dashboard.config)
    end,
  },
  {
    "kevinhwang91/nvim-ufo",
    cond = vim.g.vscode == nil,
    -- Same reasoning as indent-blankline/rainbow-delimiters: ufo's bufmanager only
    -- attaches via a `BufWinEnter` listener registered at setup time, with no
    -- explicit backfill over already-open buffers/windows. BufReadPost/BufNewFile
    -- get remapped to the earlier BufReadPre by lazy.nvim, which reliably fires
    -- before BufWinEnter for the same buffer.
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "kevinhwang91/promise-async",
    },
    opts = {
      open_fold_hl_timeout = 150,
      preview = {
        win_config = {
          border = "rounded",
          winhighlight = "Normal:Folded",
          winblend = 40,
          maxheight = 25,
        },
        mappings = {
          scrollU = "<C-u>",
          scrollD = "<C-d>",
          jumpTop = "<Home>",
          jumpBot = "<End>",
        },
      },
      provider_selector = function(_, _, _)
        return { "treesitter", "indent" }
      end,
    },
    config = function(_, opts)
      -- Load ufo
      local ufo = require("ufo")

      -- Set nvim folding options
      vim.o.foldcolumn = "1" -- '0' is not bad
      vim.o.foldlevel = 99 -- Using ufo provider need a large value
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      -- Copy the virtual text of a folded line truncated to a given width
      local function _fold_handler_rec(orig_text, new_text, max_width, new_width, truncate, prev_index)
        local index, chunk = next(orig_text, prev_index)
        if index ~= nil and chunk ~= nil then
          local chunk_text = chunk[1]
          local chunk_hl_group = chunk[2]
          local chunk_width = vim.fn.strdisplaywidth(chunk_text)
          if new_width + chunk_width < max_width then
            table.insert(new_text, { chunk_text, chunk_hl_group })
            new_width = new_width + chunk_width
            return _fold_handler_rec(orig_text, new_text, max_width, new_width, truncate, index)
          end
          chunk_text = truncate(chunk_text, max_width - new_width)
          chunk_width = vim.fn.strdisplaywidth(chunk_text)
          table.insert(new_text, { chunk_text, chunk_hl_group })
          new_width = new_width + chunk_width
        end
        return new_text, new_width
      end

      -- Custom fold handler
      local function fold_handler(virt_text, lnum, end_lnum, width, truncate)
        local suffix = (" 󰁂 %d  "):format(end_lnum - lnum)
        local target_width = width - vim.fn.strdisplaywidth(suffix)
        local result_text, result_width = _fold_handler_rec(virt_text, {}, target_width, 0, truncate)
        local spaces = (" "):rep(target_width - result_width)
        table.insert(result_text, { suffix .. spaces, "MoreMsg" })
        return result_text
      end

      -- Set the fold handler
      opts.fold_virt_text_handler = fold_handler

      -- Setup ufo
      ufo.setup(opts)

      -- Set key mappings
      vim.keymap.set("n", "zR", ufo.openAllFolds)
      vim.keymap.set("n", "zM", ufo.closeAllFolds)
      vim.keymap.set("n", "zK", function()
        if not ufo.peekFoldedLinesUnderCursor() then
          vim.lsp.buf.hover()
        end
      end)
    end,
  },
  {
    "rcarriga/nvim-notify",
    -- cond = vim.g.vscode == nil,
    cond = false,
    opts = {
      background_colour = "Conceal",
      --background_colour = "NotifyBackground",
      level = 2,
      minimum_width = 25,
      render = "minimal",
      -- fps = 40,
      -- stages = "fade",
      timeout = 4000,
      top_down = false,
      time_formats = {
        notification = "%a, %I:%M %p",
        notification_history = "%F %T%z",
      },
    },
  },
  {
    "folke/noice.nvim",
    -- cond = false,
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      -- -- OPTIONAL:
      -- -- `nvim-notify` is only needed, if you want to use the notification view.
      -- -- If not available, we use `mini` as the fallback
      -- "rcarriga/nvim-notify",
    },
    opts = {
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = false, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
      cmdline = {
        enabled = true, -- enables the Noice cmdline UI
        view = "cmdline", -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
        format = {
          -- conceal: (default=true) This will hide the text in the cmdline that matches the pattern.
          -- view: (default is cmdline view)
          -- opts: any options passed to the view
          -- icon_hl_group: optional hl_group for the icon
          -- title: set to anything or empty string to hide
          cmdline = { pattern = "^:", icon = ">", lang = "vim" },
          search_up = { kind = "search", pattern = "^%?", icon = "󱡴 ", lang = "regex" },
          search_down = { kind = "search", pattern = "^/", icon = "󱡴 ", lang = "regex" },
          filter = { pattern = "^:%s*!", icon = "", lang = "bash" },
          lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
          help = { pattern = "^:%s*he?l?p?%s+", icon = "?" },
          input = { view = "cmdline_input", icon = "󰥻 " }, -- Used by input()
        },
      },
      messages = {
        -- NOTE: If you enable messages, then the cmdline is enabled automatically.
        -- This is a current Neovim limitation.
        enabled = true, -- enables the Noice messages UI
        -- view = "notify", -- default view for messages
        -- view_error = "notify", -- view for errors
        -- view_warn = "notify", -- view for warnings
        view_history = "messages", -- view for :messages
        -- view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
        view_search = false, -- view for search count messages. Set to `false` to disable
      },
      popupmenu = {
        enabled = true, -- enables the Noice popupmenu UI
        ---@type 'nui'|'cmp'
        backend = "nui", -- backend to use to show regular cmdline completions
        ---@type NoicePopupmenuItemKind|false
        -- Icons for completion item kinds (see defaults at noice.config.icons.kinds)
        -- kind_icons = {}, -- set to `false` to disable icons
      },
      notify = {
        -- Noice can be used as `vim.notify` so you can route any notification like other messages
        -- Notification messages have their level and other properties set.
        -- event is always "notify" and kind can be any log level as a string
        -- The default routes will forward notifications to nvim-notify
        -- Benefit of using Noice for this is the routing and consistent history view
        enabled = false,
        -- view = "notify",
      },
      lsp = {
        -- disable lsp loading progress view
        progress = {
          -- enabled = true,
          enabled = false,
          -- Lsp Progress is formatted using the builtins for lsp_progress. See config.format.builtin
          -- See the section on formatting for more details on how to customize.
          -- --- @type NoiceFormat|string
          -- format = "lsp_progress",
          -- --- @type NoiceFormat|string
          -- format_done = "lsp_progress_done",
          -- throttle = 1000 / 30, -- frequency to update lsp progress message
          -- view = "mini",
        },
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
        hover = {
          -- enabled = true,
          -- silent = false, -- set to true to not show a message if hover is not available
          -- view = nil, -- when nil, use defaults from documentation
          ---@type NoiceViewOptions
          opts = {},
        },
        signature = {
          enabled = true,
          -- auto_open = {
          --   enabled = true,
          --   trigger = true, -- Automatically show signature help when typing a trigger character from the LSP
          --   luasnip = true, -- Will open signature help when jumping to Luasnip insert nodes
          --   throttle = 50, -- Debounce lsp signature help request by 50ms
          -- },
          -- view = nil, -- when nil, use defaults from documentation
          ---@type NoiceViewOptions
          opts = {}, -- merged with defaults from documentation
        },
        message = {
          -- Messages shown by lsp servers
          enabled = true,
          -- view = "notify",
          view = "mini",
          opts = {},
        },
        -- defaults for hover and signature help
        documentation = {
          view = "hover",
          ---@type NoiceViewOptions
          opts = {
            -- lang = "markdown",
            -- replace = true,
            -- render = "plain",
            -- format = { "{message}" },
            -- win_options = { concealcursor = "n", conceallevel = 3 },
            border = { style = "rounded" },
            scrollbar = false,
          },
        },
      },
      markdown = {
        hover = {
          ["|(%S-)|"] = vim.cmd.help, -- vim help links
          ["%[.-%]%((%S-)%)"] = require("noice.util").open, -- markdown links
        },
        highlights = {
          ["|%S-|"] = "@text.reference",
          ["@%S+"] = "@parameter",
          ["^%s*(Parameters:)"] = "@text.title",
          ["^%s*(Return:)"] = "@text.title",
          ["^%s*(See also:)"] = "@text.title",
          ["{%S-}"] = "@parameter",
        },
      },
    },
    config = function(_, opts)
      local noice = require("noice")
      local noice_lsp = require("noice.lsp")

      -- Set up noice
      noice.setup(opts)

      -- Scroll inside LSP hover docs
      vim.keymap.set({ "n", "i", "s" }, "<C-b>", function()
        if not noice_lsp.scroll(-4) then
          return "<C-b>"
        end
      end, { silent = true, expr = true })
      vim.keymap.set({ "n", "i", "s" }, "<C-f>", function()
        if not noice_lsp.scroll(4) then
          return "<C-f>"
        end
      end, { silent = true, expr = true })
      -- Normal only; cmp owns <C-u>/<C-d> in insert mode
      vim.keymap.set({ "n" }, "<C-u>", function()
        if not noice_lsp.scroll(-4) then
          return "<C-u>"
        end
      end, { silent = true, expr = true })
      vim.keymap.set({ "n" }, "<C-d>", function()
        if not noice_lsp.scroll(4) then
          return "<C-d>"
        end
      end, { silent = true, expr = true })
    end,
  },
}
