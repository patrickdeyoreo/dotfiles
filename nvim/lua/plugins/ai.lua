return {
  {
    "ravitemer/mcphub.nvim",
    cond = vim.g.vscode == nil,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    -- Only run the global npm install when npm is actually available.
    -- The plugin itself works without npm at runtime when `server_url` points
    -- at an externally-managed mcp-hub (e.g. systemd/launchd-supervised).
    build = vim.fn.executable("npm") == 1 and "npm install -g mcp-hub@latest" or nil,
    opts = function()
      return {
        -- Connect to the launchd-managed mcp-hub at ~/Library/LaunchAgents/com.patrickdeyoreo.mcphub.plist
        -- instead of spawning a duplicate on a different port. Falls back to
        -- the plugin spawning its own hub if this URL is unreachable.
        server_url = "http://localhost:37373",
        native_servers = {
          orchestrator = require("servers.orchestrator"),
        },
        extensions = {
          avante = {
            make_slash_commands = true, -- make /slash commands from MCP server prompts
            make_tools = true,
            make_vars = true,
          },
        },
      }
    end,
    config = function(_, opts)
      require("mcphub").setup(opts)
    end,
  },
  {
    "yetone/avante.nvim",
    cond = vim.g.vscode == nil,
    build = "make",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    keys = {
      {
        "<leader>a<Tab>",
        function()
          require("avante.extensions.nvim_tree").add_file()
        end,
        desc = "Select file in NvimTree",
        ft = "NvimTree",
      },
      {
        "<leader>a<S-Tab>",
        function()
          require("avante.extensions.nvim_tree").remove_file()
        end,
        desc = "Deselect file in NvimTree",
        ft = "NvimTree",
      },
    },
    opts = {
      -- this file can contain specific instructions for your project
      instructions_file = "avante.md",
      mode = "agentic",
      -- provider = "cursor-agent",
      provider = "claude-code",
      -- NOTE: Avante's "Cursor Tab"-style auto_suggestions is intentionally OFF.
      -- It is experimental and lower quality than a dedicated engine, it cannot
      -- reuse our ACP provider (claude-code / cursor-agent) -- it needs a separate
      -- API-key provider -- and pointing it at `copilot` risks Copilot account
      -- suspension (yetone/avante.nvim#1048). copilot.lua owns inline ghost text.
      auto_suggestions_provider = "copilot",
      behaviour = {
        auto_suggestions = false, -- inline suggestions handled by copilot.lua
        enable_fastapply = true,
        auto_add_current_file = true,
        auto_approve_tool_permissions = true,
      },
      ask = {
        floating = true, -- Open the 'AvanteAsk' prompt in a floating window
        start_insert = true, -- Start insert mode when opening the ask window
        border = "rounded",
        ---@type "ours" | "theirs"
        focus_on_apply = "ours", -- which diff to focus after applying
      },
      acp_providers = {
        ["cursor-agent"] = {
          command = vim.fn.exepath("cursor-agent"),
          args = { "acp" },
          auth_method = "cursor_login",
          env = {
            HOME = os.getenv("HOME"),
            PATH = os.getenv("PATH"),
          },
        },
        ["claude-code"] = {
          command = "npx",
          args = { "@agentclientprotocol/claude-agent-acp" },
          env = {
            NODE_NO_WARNINGS = "1",
            ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY"),
            CLAUDE_CODE_OAUTH_TOKEN = os.getenv("CLAUDE_CODE_OAUTH_TOKEN"),
            ACP_PERMISSION_MODE = "bypassPermissions",
          },
        },
      },
      shortcuts = {
        {
          name = "refactor",
          description = "Refactor code with best practices",
          prompt = "Please refactor this code following best practices.",
        },
      },
      system_prompt = function()
        local hub = require("mcphub").get_hub_instance()
        return hub and hub:get_active_servers_prompt() or ""
      end,
      -- Using function prevents requiring mcphub before it's loaded
      custom_tools = function()
        return {
          require("mcphub.extensions.avante").mcp_tool(),
        }
      end,
      -- mcphub provides equivalent tools
      disabled_tools = {
        "list_files", -- Built-in file operations
        "search_files",
        "read_file",
        "create_file",
        "rename_file",
        "delete_file",
        "create_dir",
        "rename_dir",
        "delete_dir",
        "bash", -- Built-in terminal access
      },
      spinner = {
        generating = {
          "·",
          "✢",
          "✳",
          "∗",
          "✻",
          "✽",
        }, -- Spinner characters for the 'generating' state
        thinking = {
          "·   ✧",
          "·  ✧ ",
          "· ✧  ",
          "✧·   ",
          " ✧·  ",
          "  ✧· ",
          "   ✧·",
          "  ✧· ",
          " ✧·  ",
          "✧·   ",
          "· ✧  ",
          "·  ✧ ",
        },
      },
      input = {
        provider = "snacks",
        enabled = true,
        provider_opts = {
          title = "<avante input>",
        },
      },
      selector = {
        provider = "fzf_lua",
        provider_opts = {},
        exclude_auto_select = { "NvimTree" },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      -- "nvim-mini/mini.pick", -- for file_selector provider mini.pick
      -- "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "saghen/blink.cmp", -- completion for avante commands/mentions (via blink-cmp-avante)
      "ibhagwan/fzf-lua", -- for file_selector provider fzf
      "stevearc/dressing.nvim", -- for input provider dressing
      "folke/snacks.nvim", -- for input provider snacks
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      -- "zbirenbaum/copilot.lua", -- for providers='copilot'
      { "HakonHarnes/img-clip.nvim" },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
  {
    "zbirenbaum/copilot.lua",
    cond = vim.g.vscode == nil,
    event = "InsertEnter",
    cmd = "Copilot",
    -- copilot-lsp powers Next Edit Suggestions (NES): Copilot predicts your *next
    -- edit location* and you <Tab> through/accept them -- the Cursor-Tab feature.
    dependencies = { "copilotlsp-nvim/copilot-lsp" },
    opts = {
      panel = { enabled = false },
      -- Next Edit Suggestions (requires copilot-lsp). auto_trigger surfaces a
      -- predicted edit after each change; <Tab> in normal mode jumps to/accepts it
      -- (passthrough-safe: falls back to the normal <Tab>/<C-i> when none is pending).
      nes = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept_and_goto = "<Tab>",
          accept = false,
          dismiss = false, -- clears on next edit; avoid remapping <Esc>
        },
      },
      suggestion = {
        enabled = true,
        -- The real config key is `auto_trigger` (see copilot.lua's SuggestionConfig);
        -- `auto_refresh` doesn't exist and was silently ignored, so suggestions never
        -- showed up on their own -- only after `next`/`prev`/`accept` forced a first
        -- request (trigger_on_accept). That's why multi-line ghost text felt broken:
        -- by the time a slower multi-line completion came back, <Tab> had already
        -- fallen through to blink instead of accepting it.
        auto_trigger = true,
        -- Doesn't gate anything against blink.cmp specifically -- blink renders its own
        -- floating window rather than the native popup-menu, so `vim.fn.pumvisible()`
        -- (what get_current_suggestion checks) never sees it; both blink's menu and
        -- copilot's ghost text already show at once regardless of this setting. But it
        -- ALSO gates a second path (on_text_changed_p, on the TextChangedP autocmd):
        -- when false, Copilot auto-requests a new suggestion on every keystroke even
        -- while a NATIVE (non-blink) completion popup is open (e.g. omni-completion).
        -- Leave this true to keep that narrower, safer default -- it costs nothing for
        -- the blink+copilot coexistence this config actually wants.
        hide_during_completion = true,
        debounce = 150,
        trigger_on_accept = true,
        keymap = {
          -- Reimplemented on blink's <M-Tab> in completion.lua instead (alongside NES
          -- accept) -- this is buffer-local and would otherwise always shadow that
          -- global mapping regardless of load order.
          accept = false,
          accept_line = "<M-Bslash>",
          accept_word = "<C-Right>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<M-BS>",
        },
      },
      copilot_node_command = "node",
      workspace_folders = {},
      -- copilot-language-server tries to store its OAuth token via macOS Keychain
      -- (through @github/keytar, service "copilot-language-server") on every
      -- session start, prompting for keychain access each time. This setting
      -- (an officially supported override, not a hack) skips that and falls back
      -- to the server's own plaintext-file token storage instead.
      server_opts_overrides = {
        cmd_env = {
          GITHUB_COPILOT_AUTH_TOKEN_ENCRYPTION = "false",
        },
      },
    },
  },
  {
    "Exafunction/windsurf.vim",
    cond = false,
    -- cond = vim.g.vscode == nil,
    event = "BufEnter",
  },
  {
    "olimorris/codecompanion.nvim",
    cond = vim.g.vscode == nil,
    -- Complementary to Avante: Avante for diff-first agentic edits, CodeCompanion
    -- for the modular chat buffer / prompt library / slash-commands. Lazy-loaded on
    -- first use so it doesn't pay startup cost when only Avante/Copilot are used.
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd" },
    keys = {
      { "<leader>i", "", desc = "+CodeCompanion", mode = { "n", "v" } },
      { "<leader>ia", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "Action palette" },
      { "<leader>ic", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Toggle chat" },
      { "<leader>ii", ":CodeCompanion ", mode = { "n", "v" }, desc = "Inline assistant" },
      { "<leader>ix", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add selection to chat" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/mcphub.nvim",
      "ravitemer/codecompanion-history.nvim",
      "saghen/blink.cmp", -- chat-buffer completion (self-registers a blink source)
    },
    opts = {
      adapters = {
        acp = {
          -- Claude Code over ACP. The shipped adapter invokes a bare
          -- `claude-agent-acp` binary, which is not on our PATH; run it via npx
          -- instead, mirroring the Avante claude-code provider. Auth accepts
          -- whichever credential the environment provides (OAuth token or API key).
          claude_code = function()
            return require("codecompanion.adapters").extend("claude_code", {
              commands = {
                default = { "npx", "@agentclientprotocol/claude-agent-acp" },
              },
              env = {
                CLAUDE_CODE_OAUTH_TOKEN = "CLAUDE_CODE_OAUTH_TOKEN",
                ANTHROPIC_API_KEY = "ANTHROPIC_API_KEY",
              },
              handlers = {
                auth = function(self)
                  local ok = false
                  for _, key in ipairs({ "CLAUDE_CODE_OAUTH_TOKEN", "ANTHROPIC_API_KEY" }) do
                    local val = self.env_replaced and self.env_replaced[key]
                    if val and val ~= "" then
                      vim.env[key] = val
                      ok = true
                    end
                  end
                  return ok
                end,
              },
            })
          end,
        },
      },
      interactions = {
        -- Chat over the Claude Code ACP: reuses CLAUDE_CODE_OAUTH_TOKEN (the same
        -- auth that powers Avante), so no ANTHROPIC_API_KEY is required. Claude Code
        -- selects the model. To use the HTTP API instead: adapter = "anthropic",
        -- model = "claude-sonnet-4-6" (note hyphens; needs ANTHROPIC_API_KEY).
        -- ("claude" is NOT a valid adapter name -- it was anthropic/claude_code.)
        chat = {
          adapter = "claude_code",
          opts = {
            completion_provider = "blink", -- blink|cmp|coc|default
          },
        },
        -- Inline only supports HTTP adapters (not ACP, so not claude_code), so it
        -- uses the authenticated Copilot subscription for fast in-buffer edits.
        inline = {
          adapter = "copilot",
        },
        -- Command generation is likewise HTTP-only (no ACP), so it also uses Copilot.
        cmd = {
          adapter = "copilot",
          opts = {
            completion_provider = "blink", -- blink|cmp|coc|default
          },
        },
        -- background = {
        --   adapter = {
        --     name = "ollama",
        --     model = "qwen-7b-instruct",
        --   },
        -- }
      },
      extensions = {
        history = {
          enabled = true, -- defaults to true
          opts = {
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion/chat_history.json",
          },
        },
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            -- MCP Tools
            make_tools = true,
            show_server_tools_in_chat = true,
            add_mcp_prefix_to_tool_names = false,
            show_result_in_chat = true,
            -- MCP Resources
            make_vars = false, -- Broken, tries to access 'variables'
            -- MCP Prompts
            make_slash_commands = true,
          },
        },
      },
    },
  },
}

