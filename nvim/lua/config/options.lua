-- options.lua: set editor options
-- This file is automatically loaded by plugins.core
local M = {}

local defaults = {
  values = {
    encoding = "utf-8",
    autoread = true,
    autowrite = true,
    backspace = "indent,eol,start",
    belloff = "all",
    clipboard = (vim.env.SSH_TTY == nil or vim.fn.has("nvim-0.10") == 1) and "unnamedplus" or "", -- Use OSC52 over SSH on nvim-0.10+, otherwise system clipboard
    cmdheight = vim.g.vscode and 2 or 0, -- vscode-neovim shows its output panel once a message exceeds this many lines
    complete = ".,w,b,u,t,i",
    completeopt = "fuzzy,noselect,menuone,popup",
    conceallevel = 2, -- Hide * markup for bold and italic
    confirm = true, -- Confirm to save changes before exiting modified buffer
    cursorline = true, -- Enable highlighting of the current line
    cursorlineopt = "line,number",
    display = "uhex,lastline",
    expandtab = true, -- Use spaces instead of tabs
    foldlevel = 99,
    formatoptions = "jcroqlnt",
    grepformat = "%f:%l:%c:%m",
    grepprg = "rg --vimgrep",
    hidden = true,
    history = 10000,
    hlsearch = false, -- Do not highlight search results
    ignorecase = true, -- Ignore casei
    inccommand = "nosplit", -- preview incremental substitute
    incsearch = true,
    jumpoptions = "view",
    keywordprg = ":Man",
    laststatus = 3, -- global statusline
    linebreak = true, -- Wrap lines at convenient points
    list = true, -- Show some invisible characters (tabs...
    modeline = true,
    mouse = "a", -- Enable mouse mode
    mousefocus = true,
    nrformats = "bin,hex,unsigned",
    number = true, -- Show line numbers
    numberwidth = 3, -- Min width of number column
    pumblend = 11, -- Popup blend
    pumheight = 30, -- Maximum number of entries in a popup
    relativenumber = false, -- Give us absolute line numbers
    report = vim.g.vscode and 9999 or 2,
    ruler = true, -- Enable the default ruler
    scrolloff = 3, -- Lines of context
    sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds",
    shiftround = true, -- Round indent
    showcmd = true,
    showcmdloc = "tabline",
    showmatch = true,
    showmode = false, -- Dont show mode since we have a statusline
    sidescroll = 1,
    sidescrolloff = 3, -- Columns of context
    signcolumn = "yes", -- Always show the signcolumn, otherwise it would shift the text each time
    smartcase = true, -- Don't ignore case with capitals
    smartindent = true, -- Insert indents automatically
    smoothscroll = vim.fn.has("nvim-0.10") == 1 or nil,
    softtabstop = 2,
    spelllang = "en",
    splitbelow = true, -- Put new windows below current
    splitkeep = "screen",
    splitright = true, -- Put new windows right of current
    startofline = false,
    tabstop = 8, -- Number of spaces per tab
    tags = ".tags,.TAGS,tags,TAGS",
    termguicolors = true, -- True color support
    timeout = true,
    timeoutlen = vim.g.vscode and 1000 or 500, -- Lower than default (1000) to quickly trigger which-key
    undolevels = 2500,
    undoreload = -1,
    updatecount = 25, -- Save swap file and trigger CursorHold
    virtualedit = "block", -- Allow cursor to move where there is no text in visual block mode
    whichwrap = "<,>,[,],b,s",
    wildignore = table.concat({ ".git/*", ".hg/*", ".svn/*" }, ","),
    wildignorecase = true,
    wildmenu = true,
    wildmode = "longest:noselect,full", -- Command-line completion mode
    winblend = 10,
    winborder = vim.fn.has("nvim-0.11") == 1 and "rounded" or nil, -- Added in 0.11
    winminwidth = 10, -- Minimum window width
  },
  hooks = {
    before = {},
    after = {
      shiftwidth = function()
        return vim.o.expandtab and vim.o.softtabstop or 0
      end,
      _shortmess = function()
        vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
        if vim.g.vscode then
          vim.opt.shortmess:append({ S = true })
        end
      end,
      _directory = function()
        vim.opt.directory:prepend(string.format("%s/swap/", vim.fn.stdpath("state")))
        vim.opt.directory:append(string.format("%s/nvim/swap/", vim.fn.stdpath("run")))
      end,
      _backupdir = function()
        vim.opt.backupdir:prepend(string.format("%s/backup/", vim.fn.stdpath("state")))
        vim.opt.backupdir:append(string.format("%s/nvim/backup/", vim.fn.stdpath("run")))
      end,
      _undodir = function()
        vim.opt.undodir:prepend(string.format("%s/undo/", vim.fn.stdpath("state")))
        vim.opt.undodir:append(string.format("%s/nvim/undo/", vim.fn.stdpath("run")))
      end,
      _undofile = function()
        local ephemeral_patterns = {
          "/run/*",
          "/var/run/*",
          string.format("%s/*", vim.fn.stdpath("run") or "/var/run"),
          "/tmp/*",
          "/var/tmp/*",
          string.format("%s/*", vim.env.TMPDIR or "/var/tmp"),
        }
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = vim.api.nvim_create_augroup("user_noundofile", { clear = true }),
          pattern = ephemeral_patterns,
          -- 'undofile' is local to buffer (see :h 'undofile'), so we use vim.bo
          -- here (equivalent to :setlocal noundofile). Using vim.o would change
          -- the global default and leak the override to unrelated future buffers.
          callback = function()
            vim.bo.undofile = false
          end,
          desc = "Disable persistent undo in ephemeral directories",
        })
        vim.o.undofile = vim.o.swapfile
      end,
    },
  },
}

local _add_default_hook_funcs = function(hook_funcs, group)
  local alt_key
  for key, value in pairs(defaults.hooks[group] or {}) do
    if string.sub(key, 1, 1) == "_" then
      alt_key = string.sub(key, 2)
    else
      alt_key = "_" .. key
    end
    if hook_funcs[key] == nil and hook_funcs[alt_key] == nil then
      hook_funcs[key] = value
    end
  end
  return hook_funcs
end

local _add_default_hooks = function(hooks)
  for group, _ in pairs(defaults.hooks) do
    hooks[group] = _add_default_hook_funcs(hooks[group] or {}, group)
  end
  return hooks
end

local _add_default_values = function(values)
  for key, value in pairs(defaults.values) do
    if values[key] == nil then
      values[key] = value
    end
  end
  return values
end

local _run_hook_funcs = function(hook_funcs)
  for key, func in pairs(hook_funcs) do
    local value = func()
    if string.sub(key, 1, 1) ~= "_" then
      vim.o[key] = value
    end
  end
end

M.setup = function(opts)
  local values = _add_default_values(opts and opts["values"] or {})
  local hooks = _add_default_hooks(opts and opts["hooks"] or {})
  _run_hook_funcs(hooks.before)
  for key, value in pairs(values) do
    vim.o[key] = value
  end
  _run_hook_funcs(hooks.after)
end

return M
