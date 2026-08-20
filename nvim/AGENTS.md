# Neovim Configuration — Handover Document

## Overview

This is a personal Neovim configuration located at `~/.local/etc/nvim` (symlinked or set via `$XDG_CONFIG_HOME`). It is part of a larger dotfiles repository rooted at `~/.local/etc`. The config is written entirely in Lua, uses [lazy.nvim](https://github.com/folke/lazy.nvim) as the plugin manager, and is designed to work both as a standalone Neovim instance and inside VSCode (via the vscode-neovim extension).

## Directory Structure

```
nvim/
├── init.lua                     # Entry point: options, leader keys, keymaps, plugin bootstrap
├── lazy-lock.json               # lazy.nvim lockfile (pinned plugin versions)
├── lua/
│   ├── config/
│   │   ├── init.lua             # Config module aggregator (exposes options + lazy)
│   │   ├── options.lua          # Editor options with default values and hook system
│   │   └── lazy.lua             # lazy.nvim bootstrap + fold/format integration with native nvim builtins
│   ├── core/
│   │   └── utils.lua            # Shared utility helpers (get_hlgroup, get_buffer_count, parse_hex)
│   ├── utils/
│   │   ├── init.lua             # Utils module aggregator (exposes colors)
│   │   └── colors.lua           # Colorscheme rotation engine (Deque + Playlist data structures)
│   └── plugins/                 # All plugin specs (auto-imported by lazy.nvim)
│       ├── ai.lua               # AI assistants: Avante, Copilot, MCPHub, CodeCompanion
│       ├── colorschemes.lua     # Colorscheme plugins (cyberdream, rose-pine, nightfox, etc.)
│       ├── completion.lua       # blink.cmp setup with multiple sources and custom mappings
│       ├── copypaste.lua        # yanky.nvim — persistent yank ring with sqlite storage
│       ├── dap.lua              # Debug Adapter Protocol: nvim-dap, dap-ui, Go + Python adapters
│       ├── diagnostics.lua      # tiny-inline-diagnostic, todo-comments, nvim-lint, Trouble
│       ├── editing.lua          # nvim-surround, treesj, nvim-autopairs (leap disabled)
│       ├── env.lua              # ecolog.nvim — environment variable management and shelter
│       ├── explorers.lua        # nvim-tree file explorer (right-side panel, netrw disabled)
│       ├── formatting.lua       # conform.nvim — format-on-save and :FormatToggle
│       ├── fzf.lua              # fzf-lua — primary fuzzy finder (replaces telescope)
│       ├── git.lua              # Git: gitsigns, neogit, git-conflict
│       ├── images.lua           # img-clip.nvim — image paste support
│       ├── keymaps.lua          # which-key.nvim — keymap discovery with helix preset
│       ├── lsp.lua              # LSP: nvim-lspconfig, mason, mason-lspconfig, navic, lazydev
│       ├── markdown.lua         # Markdown preview + render-markdown.nvim
│       ├── mini.lua             # mini.icons + mini.comment
│       ├── movement.lua         # flash.nvim motions (jump / treesitter select)
│       ├── nvim-treesitter.lua  # Treesitter: parsers, context, textobjects (select/move/swap)
│       ├── repl.lua             # Conjure REPL integration (disabled by default)
│       ├── search.lua           # grug-far.nvim — search and replace
│       ├── sessions.lua         # persistence.nvim sessions + neorg note-taking
│       ├── snacks.lua           # snacks.nvim — multipurpose utility (picker, scroll, indent, etc.)
│       ├── snippets.lua         # LuaSnip + friendly-snippets
│       ├── terminal.lua         # toggleterm.nvim — integrated terminal
│       └── ui.lua               # UI: lualine, bufferline, indent-blankline, ufo (folding),
│                                #     noice, alpha (dashboard), bqf, vim-illuminate, nvim-notify
└── lazy/                        # lazy.nvim cache and state (auto-generated, do not edit)
```

## Initialization Flow

1. **`init.lua`** loads the `config` and `utils` packages (aggregator modules that expose submodules; they do not provide a `setup()` — submodules are setup directly)
2. **`config.options.setup()`** applies all editor options (see `lua/config/options.lua`)
3. Leader keys are set: `mapleader = ","` and `maplocalleader = ";"`
4. **`config.lazy.setup(...)`** bootstraps lazy.nvim and imports all plugin specs from `lua/plugins/`
5. If NOT in VSCode (`vim.g.vscode == nil`):
   - A curated colorscheme list is set on `vim.g.colorschemes`
   - The colorscheme rotation engine (`utils.colors.setup()`) is initialized and `colors.restore()` re-applies the scheme cached for the current `&background` (falling back to a background-filtered shuffle)
   - Global keymaps are bound (function keys, window/buffer navigation, visual line moves, etc.)

## VSCode Compatibility

Most plugins use `cond = vim.g.vscode == nil` to disable themselves inside VSCode. The lazy.nvim setup also sets `defaults.cond = not vim.g.vscode`. Plugins that work in both contexts (e.g., nvim-surround, flash, treesj, autopairs, treesitter) use `cond = true` to force-enable.

## Leader Key and Keymap Conventions

| Prefix | Group | Examples |
|---|---|---|
| `,` | **mapleader** | All `<leader>` mappings |
| `;` | **maplocalleader** | Filetype-local / Conjure |
| `<leader>a` | AI | Avante file select (`a+`, `a-`) |
| `<leader>b` | Buffers | `bd` delete, `bn`/`bp` navigate, `bb` picker |
| `<leader>c` | Comment | `cc` line, `c` visual toggle (mini.comment) |
| `<leader>d` | Debug | `db` breakpoint, `dc` continue, `du` UI toggle |
| `<leader>e` | Env | ecolog peek, copy, toggle |
| `<leader>g` | Git | gitsigns stage/reset/blame, neogit |
| `<leader>i` | CodeCompanion | `ia` actions, `ic` toggle chat, `ii` inline assistant, `ix` add selection to chat (visual) |
| `<leader>l` | LSP | `la` code action, `lr` rename, `lf` format |
| `<leader>m` | Explorer | `M` toggle nvim-tree, `mm` reveal current file |
| `<leader>n` | Notifications | Snacks notification history |
| `<leader>p` | Yank History | yanky.nvim picker |
| `<leader>q` | Session | persistence.nvim load/save/select |
| `<leader>s` | Search | `sr` grug-far search & replace |
| `<leader>w` | Windows | `wh/j/k/l` navigate, `ws/wv` split, `wq` close |
| `<leader>x` | Diagnostics | Trouble toggles |
| `` <leader>` `` | Terminal | toggleterm send lines |
| `<leader><leader>` | Quick Save | `:w` |
| `<Space>` | TreeSJ | `t` toggle, `s` split, `j` join |
| `s` (n/x/o) | Flash | Jump |
| `S` (n/o) | Flash Treesitter | Treesitter select (visual `S` belongs to nvim-surround) |
| `r` (o) / `R` (o/x) | Flash | Remote flash / Treesitter search |
| `af`/`if` `ac`/`ic` `aa`/`ia` `al`/`il` `ao`/`io` | Textobjects (select) | around / inside function, class, argument, loop, conditional |
| `]f`/`[f` `]c`/`[c` (and `]F`/`[F`, `]C`/`[C` for ends) | Textobjects (move) | Next / prev function or class |
| `<M-j>` / `<M-k>` | Textobjects (swap) | Swap parameter with next / previous |
| `<M-n>` / `<M-p>` | Textobjects (repeat) | Repeat last treesitter move forward / backward |
| `v_an` / `v_in` / `v_]n` / `v_[n` | Incremental selection | Neovim 0.12 core treesitter defaults (init/grow-outer/next-sibling/prev-sibling) |
| `F1`–`F6` | Quick Access | Tree, helptags, fzf global, grug-far, keymaps, commands |
| `F10` | Toggle hlsearch | |
| `F11`/`F12`/`F24` | Colorscheme | Previous / Next / Shuffle |

## Key Architectural Decisions

### Plugin Manager: lazy.nvim
- Bootstrapped in `lua/config/lazy.lua` via git clone
- Uses Neovim's native `vim.lsp.formatexpr()` for `formatexpr` and `vim.treesitter.foldexpr()` for fold expression (no LazyVim dependency)
- Plugin specs are auto-discovered from `lua/plugins/` via `{ import = "plugins" }`
- The plugin checker is disabled (`checker.enabled = false`)

### Options System (`lua/config/options.lua`)
- Uses a declarative `defaults.values` table for all `vim.o` options
- Supports before/after hooks for complex option logic (e.g., `shiftwidth` derived from `softtabstop`, undo/swap/backup directory setup)
- Hook keys prefixed with `_` are "private" — they run side effects without setting a `vim.o` value

### Colorscheme Rotation (`lua/utils/colors.lua`)
- Custom `Deque` (doubly-linked circular list) and `Playlist` data structures
- `Playlist:next()` cycles forward, trying `pcall(vim.cmd.colorscheme, name)` for each candidate
- `Playlist:prev()` cycles backward; `Playlist:next(true)` shuffles randomly
- Exposed via `colors.next()`, `colors.prev()`, `colors.shuffle()`, bound to F11/F12/F24

### Completion (`lua/plugins/completion.lua`)
- **Engine**: [blink.cmp](https://github.com/Saghen/blink.cmp), pinned to `version = "1.*"` (prebuilt Rust fuzzy matcher — no local build; needs `curl`+`git`). Migrated off nvim-cmp.
- Sources via `score_offset` priority (was cmp's grouped sources): `lazydev` (100) > `avante` (90, via `blink-cmp-avante`) > `ecolog` (50, native `ecolog.integrations.cmp.blink_cmp`) > `git` (40, native `blink-cmp-git`, only in `gitcommit`/`NeogitCommitMessage`/`octo` via `per_filetype` + `inherit_defaults`) > `lsp`/`path`/`snippets` > `buffer` (-10). CodeCompanion self-registers its own blink source for `codecompanion`/`codecompanion_input` filetypes.
- Snippets: `snippets.preset = "luasnip"` (LuaSnip defined in `snippets.lua`; no `cmp_luasnip` bridge needed).
- Keymaps start from the `default` preset and override several keys, most notably a smart, multi-key scheme that arbitrates between blink's menu, Copilot's ghost-text suggestion, and NES (see the AI Stack section below for the full behavior): `<Tab>` selects-next when the menu is open, else accepts a Copilot suggestion, else jumps forward in a snippet, else triggers completion on a non-whitespace prefix (literal Tab otherwise); `<S-Tab>` accepts a pending NES edit directly when the menu is closed, else the standard `select_prev` cycle (deliberately not `<M-Tab>` — most window managers grab Alt-Tab before it reaches the terminal); `<C-Tab>` dismisses blink/the suggestion/any pending NES and inserts a literal tab; `<Esc>` = `{ "cancel", "fallback" }` closes blink without leaving insert mode. `get_copilot_suggestion()`/`get_copilot_nes()` at the top of the file are shared helpers for the `pcall(require(...))` + state checks these keymaps repeat. `<CR>` = `{ "accept", "fallback" }` (confirms only when an entry is selected; `selection.preselect = false`), `<C-q>` hide, `<C-Space>`/`<C-@>` show, `<C-u>`/`<C-d>`/`<PageUp>`/`<PageDown>` scroll docs, `<C-g>` toggle docs, `<C-k>` deferred to the LSP signature mapping.
- `completion.ghost_text` is **off** (Copilot owns inline ghost text). `accept.auto_brackets` is **on** — the semantic replacement for the old `nvim-autopairs` `on_confirm_done` hook (blink has no `confirm_done` event; nvim-autopairs still handles typed pairs standalone).
- Cmdline: native blink, sources chosen by `getcmdtype()` — `:`/`@` → `cmdline`+`path`, `/`/`?` → `buffer`. (The old `nvim_lsp_document_symbol` cmdline source and `<C-]>` `complete_common_string` have no blink equivalent and were dropped.)
- Menu/docs use `rounded` borders; kind icons drawn via `MiniIcons.get("lsp", kind)` in the `kind_icon` draw component.

### AI Stack (`lua/plugins/ai.lua`)
- **Primary chat/agent + fast-apply**: [Avante.nvim](https://github.com/yetone/avante.nvim) — agentic mode, `provider = "claude-code"` (Claude Code via the `@agentclientprotocol/claude-agent-acp` ACP binary; `cursor-agent` ACP is configured as an alternative). The Cursor-like diff/apply experience.
- **MCP**: [MCPHub.nvim](https://github.com/ravitemer/mcphub.nvim) — provides MCP tool access to both Avante and CodeCompanion, disables Avante's built-in file/bash tools in favor of MCP equivalents.
- **Inline ("Cursor Tab")**: `zbirenbaum/copilot.lua` — inline ghost-text suggestions on `InsertEnter`, auto-triggered as you type (`suggestion.auto_trigger = true`). Blink's menu and Copilot's ghost text can both be visible at once (`hide_during_completion` only gates a native-popup-menu edge case, not blink, which renders its own floating window). Insert-mode keys, defined in `completion.lua`'s blink keymap chains: `<Tab>` accepts the suggestion once blink's menu is closed (blink wins while open); `<S-Tab>` accepts a pending NES edit once blink's menu is closed (standard `select_prev` cycling while open) — not `<M-Tab>`, since most window managers intercept Alt-Tab before it reaches the terminal; `<C-Tab>` dismisses blink/the suggestion/any pending NES and inserts a literal tab, bypassing all of it. Avante's own experimental `auto_suggestions` is intentionally **off** (it can't reuse the ACP provider and `copilot`-as-provider risks account suspension — see the comment in `ai.lua`).
- **Next Edit Suggestions (NES)**: `copilot.lua` `nes` + the `copilotlsp-nvim/copilot-lsp` backend — Copilot predicts your *next edit location* (Cursor-Tab's signature feature). `auto_trigger = true`; in normal mode `<Tab>` jumps to/accepts the predicted edit (passthrough-safe — falls back to native `<Tab>`/`<C-i>` jumplist when no edit is pending).
- **Secondary chat (complementary)**: `olimorris/codecompanion.nvim` — **enabled** and lazy-loaded (`cmd` + `<leader>i…` keys). Modular chat buffer / prompt library / slash-commands, with `codecompanion-history.nvim` + the mcphub extension. Chat/cmd completion via blink (`completion_provider = "blink"`); self-registers its blink source. Avante and CodeCompanion coexist by design (Avante = diff-first edits, CodeCompanion = modular chat); they do not share keymaps.
- **Disabled**: Windsurf (`cond = false`).
- **Plugin manager note**: stayed on **lazy.nvim** — `rocks.nvim` was evaluated and rejected for this config (no first-class `cond` gating, function-valued opts can't live in `rocks.toml`, stale third-party Avante rockspec, treesitter friction).

### LSP (`lua/plugins/lsp.lua`)
- Uses `mason.nvim` + `mason-lspconfig.nvim` with `automatic_enable = true`
- LSP keymaps set via a single `LspAttach` autocmd (not per-server)
- `nvim-navic` breadcrumbs auto-attach when server supports `documentSymbol`
- `lazydev.nvim` provides Neovim Lua API completions (scoped to `ft = "lua"`)
- LSP client capabilities are injected via `vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })`; `nvim-lspconfig` depends on `blink.cmp` so it loads before this runs

### Formatting and Linting
- **Formatting**: `conform.nvim` in `lua/plugins/formatting.lua` with format-on-save (toggleable via `:FormatToggle` or `vim.g.disable_autoformat`)
- **Linting**: `nvim-lint`, split across two autocmds. All linters run on `BufWritePost`/`BufReadPost`; `InsertLeave` only re-runs the "fast", single-file linters (a `slow_linters` set currently containing `tflint` and `golangcilint` is excluded there) — those whole-module/whole-package tools respawn a multi-second scan on every invocation, and running them on every `InsertLeave` (i.e. every time you leave insert mode while editing) is what made editing large Terraform/Go codebases feel slow before this split existed
- Per-filetype formatter/linter assignments cover: Go, Python, JS/TS, Lua, Rust, Terraform, YAML, Shell, Markdown, HTML/CSS

### Diagnostics Display
- `tiny-inline-diagnostic.nvim` replaces default `virtual_text` (`vim.diagnostic.config({ virtual_text = false })`)
- `Trouble.nvim` for structured diagnostic/TODO/quickfix list browsing

### UI Layer
- **Statusline**: lualine with custom sections (mode, branch, diagnostics, file icon via devicons, navic breadcrumbs, ecolog env-var status, copilot status, lazy updates, clock). lualine's `opts` is a named local function (`lualine_opts`), not inline, specifically so a `User LazyLoad` autocmd can call `require("lualine").setup(lualine_opts())` again once `ecolog.nvim` (which only lazy-loads via its own `<leader>e*` keys, well after lualine's initial setup) actually loads — otherwise that component permanently bakes in as a no-op, since it's only checked once at lualine's own (now `VeryLazy`) load time. Several other UI plugins here (`bufferline`, `indent-blankline`+`rainbow-delimiters`, `nvim-ufo`) are also lazy-loaded now; see the comments at each spec for why `VeryLazy` is safe for some but `BufReadPost`/`BufNewFile` is required for others (the latter group attaches to buffers via `VimEnter`/`FileType`/`BufWinEnter`, which `VeryLazy` — firing after `VimEnter` — would miss for the first-opened buffer)
- **Tabline**: bufferline.nvim with LSP diagnostics indicators
- **Command line**: noice.nvim (classic bottom cmdline view, custom icons, treesitter markdown override)
- **Dashboard**: alpha-nvim with startify theme
- **Folding**: nvim-ufo with treesitter+indent provider and custom fold virtual text handler
- **Notifications**: nvim-notify is disabled; noice notify is also disabled; snacks notifier is primary

### Fuzzy Finding
- **Primary**: `fzf-lua` (replaces telescope, which is commented out)
- **Secondary**: `snacks.nvim` picker (used by yanky, notifications, etc.)
- fzf-lua configured with ivy/border-fused/hide profiles, tmux integration, custom color scheme

## Plugins That Are Currently Disabled

These plugins exist in the config but are set to `cond = false`:
- `Exafunction/windsurf.vim` — Windsurf AI coding (alternative to Copilot)
- `rcarriga/nvim-notify` — notification UI (replaced by snacks/noice mini)
- `Olical/conjure` + `PaterJason/cmp-conjure` — REPL integration

## External Dependencies

These tools must be available on `$PATH` for full functionality:
- `node` / `npm` — required for MCPHub, Copilot, markdown-preview
- `yarn` — required for markdown-preview build
- `rg` (ripgrep) — used as `grepprg` and by fzf-lua
- `fzf` — used by fzf-lua (also supports tmux popup via `--tmux`)
- `git` — lazy.nvim bootstrap, gitsigns, neogit
- `curl` — blink.cmp downloads its prebuilt Rust fuzzy-matcher binary (with `git` as fallback)
- `make` — Avante build, LuaSnip jsregexp
- `python3` — nvim-dap-python
- `cursor-agent` — Avante cursor ACP provider
- Language-specific: `shellcheck`, `hadolint`, `golangcilint`, `eslint_d`, `markdownlint`, `ruff`, `tflint`, `yamllint`, `prettierd`/`prettier`, `goimports`, `gofumpt`, `stylua`, `shfmt`, `taplo`, `rustfmt`, `terraform`

## Common Tasks for Maintainers

### Adding a new plugin
Create or edit a file in `lua/plugins/`. Return a table of lazy.nvim plugin specs. It will be auto-imported.

### Adding a new colorscheme
1. Add the plugin spec to `lua/plugins/colorschemes.lua`
2. Add the colorscheme name to the `vim.g.colorschemes` list in `init.lua` (the non-VSCode block)

### Changing the AI provider
Edit `lua/plugins/ai.lua`. Avante's `provider` option selects the backend. The `acp_providers` table configures the cursor-agent binary. To switch to CodeCompanion, flip its `cond` to `true` and Avante's to `false`.

### Changing formatter/linter for a filetype
- Formatters: `lua/plugins/formatting.lua` → conform.nvim `formatters_by_ft`
- Linters: `lua/plugins/diagnostics.lua` → nvim-lint `linters_by_ft`

### Modifying editor options
Edit `lua/config/options.lua`. Add values to `defaults.values` or hooks to `defaults.hooks.before`/`defaults.hooks.after`.

### Debugging startup issues
Run `nvim --startuptime /tmp/startup.log` or use `:Lazy profile`. The snacks.nvim `profile` module is also enabled.

## Known Quirks

- `Deque:pop_front()` and `Deque:pop_rear()` in `colors.lua` swap head/rear on remove — this is correct for the circular list but non-obvious
- `indent-blankline.nvim` and `rainbow-delimiters.nvim` share a scope-colored indent-guide setup: ibl's `scope.highlight` and `indent.highlight` lists point to the `RainbowDelimiter*` groups, and the `scope_highlight_from_extmark` hook links scope line colors to the enclosing bracket color when rainbow-delimiters provides an extmark (treesitter-enabled filetypes with delimiter queries)
- `rainbow-delimiters.nvim` ships a muted Gruvbox-inspired default palette. `plugins/ui.lua` overrides the `RainbowDelimiter*` highlight groups with a vivid Catppuccin-Mocha palette and re-applies them on every `ColorScheme` event so rainbow indent guides stay visible during F11/F12/F24 rotation
- `nvim-treesitter` runs on `branch = 'main'` (the full rewrite). It is intentionally not lazy-loaded per upstream. Parser installation uses an **explicit list of ~87 parsers** passed to `require('nvim-treesitter').install({...})` (async on startup, idempotent thereafter, installed to `~/.local/share/nvim/site/parser/`). Note the main-branch tier names are misleading — `'stable'` is only 7 hand-picked parsers and `'unstable'` is the 315-parser bulk (contains markdown, lua, python, etc.), so we bypass tiers entirely and curate the list. A `FileType` autocmd calls `vim.treesitter.start(buf)` wrapped in `pcall` (silently swallows errors for filetypes without a parser, e.g. `help`/`man`). `nvim-treesitter-textobjects` is also on its `main` branch with `require('nvim-treesitter-textobjects').setup{...}` and explicit `vim.keymap.set` wiring. `nvim-treesitter-context` remains on its own `master` (different repo, unchanged API)
- Incremental selection uses Neovim 0.12 core defaults (`v_an`/`v_in`/`v_]n`/`v_[n`) — the old `<leader>nn`/`<leader>rn`/`<leader>rc`/`<leader>rm` keymaps from nvim-treesitter master are retired. Semantic note: `v_]n`/`v_[n` navigate to sibling nodes (not grow to an enclosing scope); use textobject selection (e.g., `vaf`) for scope-based grow-to-function
- Treesitter move repeat lives on `<M-n>` / `<M-p>` (from `nvim-treesitter-textobjects` `repeatable_move`) because `;` / `,` are the localleader/leader keys and can't be rebound; native `f`/`F`/`t`/`T` are untouched — flash.nvim maps `s`/`S`/`r`/`R`, not `f`
- `_undofile` hook in `config/options.lua` uses `vim.bo.undofile = false` (buffer-local) inside a `BufWritePre` autocmd, matching the old `:setlocal noundofile` behavior. Using `vim.o.undofile` there would leak the disabled state to unrelated future buffers
- `ai.lua`'s copilot.lua spec sets `server_opts_overrides.cmd_env.GITHUB_COPILOT_AUTH_TOKEN_ENCRYPTION = "false"`. Without it, `copilot-language-server`'s bundled Node process tries to store its OAuth token via macOS Keychain (through `@github/keytar`) on every session start, prompting for keychain access every time. This is an officially supported override (verified by reading the server's own bundled JS — it explicitly checks for this and falls back to its own plaintext-file token storage), not a hack; the tradeoff is the token sits in a plaintext file under `~/.config/github-copilot/` instead of encrypted

## File Naming Conventions

- Plugin files are named by functional domain, not by plugin name (e.g., `editing.lua` contains surround, treesj, and autopairs; `movement.lua` contains flash; `ui.lua` contains lualine, bufferline, indent-blankline, rainbow-delimiters, ufo, noice, alpha, bqf, illuminate, and notify)
- Utility modules follow a `module/init.lua` + `module/name.lua` pattern
- The `core/utils.lua` vs `utils/` split is historical — `core/utils.lua` has UI helpers used by lualine; `utils/colors.lua` has the colorscheme engine
