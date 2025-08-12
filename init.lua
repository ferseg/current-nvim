------------------------------------------------------------------------
-- Options
------------------------------------------------------------------------
local opt = vim.opt;

opt.number = true;
opt.relativenumber = true;
opt.expandtab = true;
opt.smarttab = true;
opt.tabstop = 2;
opt.shiftwidth = 2;
opt.signcolumn = "yes"
opt.winborder = "rounded"
opt.hlsearch = false
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 300
opt.termguicolors = true
opt.conceallevel = 2
opt.cursorline = true
opt.colorcolumn = "120"
opt.scrolloff = 8
vim.g.mapleader = " "

------------------------------------------------------------------------
-- Keymaps
------------------------------------------------------------------------
local keymap = function(mode, mapping, command, desc)
  vim.keymap.set(mode, mapping, command, { desc = desc })
end

local nmap = function(mapping, command, desc)
  return keymap("n", mapping, command, desc)
end

local imap = function(mapping, command)
  return keymap("i", mapping, command)
end

keymap({"n", "i"}, "<C-s>", "<ESC>:w<CR>", "Save the current file")
nmap("<leader>r", ":update<CR>:source<CR>", "Reloads the current file")

imap("jj", "<ESC>", "Exit INSERT mode")
imap("kk", "<ESC>", "Exit INSERT mode")

------------------------------------------------------------------------
-- Plugins
------------------------------------------------------------------------
local pm = require("plugins.plugin_manager")

-- Editor theme
pm.plugin({
  "olimorris/onedarkpro.nvim",
  skip_setup = true,
})
vim.cmd("colorscheme onedark")

-- Syntax hightlighter
pm.plugin({
  "nvim-treesitter/nvim-treesitter",
  event = "BufReadPost",
  plug_setup_name = "nvim-treesitter.configs",
  opts = {
    ensure_installed = { "lua", "rust", "bash" }
  }
});

-- Predefined configuration for Laguage Servers
pm.plugin({
  "neovim/nvim-lspconfig",
  plug_setup_name = "lspconfig",
})

-- Completion feature
pm.plugin({
  "saghen/blink.cmp",
  version = "1.*",
  name = "blink",
  opts = {
    keymap = { preset = "enter" },
    completion = {
      documentation = { auto_show = true }
    }
  }
})

-- Picker so I can pick files quick
pm.plugin({
  'echasnovski/mini.pick',
  opts = {
    keymaps = {
      {"n", "<leader>sf", ":Pick files<CR>", "[S]earch [F]iles" },
      {"n", "<leader>sb", ":Pick buffers<CR>", "[S]search [B]uffers" },
    }
  }
})

-- File explorer
pm.plugin({
  'echasnovski/mini.files',
  opts = {
    keymaps = {
      {"n", "<leader>f", ":lua MiniFiles.open()<CR>", "Open [F]iles" }
    }
  }
})

pm.no_config_plugins({
  -- Word under cursos hightlighter
  'echasnovski/mini.cursorword',
  -- Custom hightlighter for TODO, NOTE, HACK, FIXME
  'echasnovski/mini.hipatterns',
  -- Icons for ui
  'echasnovski/mini.icons',
  -- Autoclose pair
  'echasnovski/mini.pairs',
  -- Status line
  'echasnovski/mini.statusline',
})

------------------------------------------------------------------------
-- LSP
------------------------------------------------------------------------
local lsp = require("plugins.lsp")
lsp.setup(
  {
    -- Enable lua language server
    { "lua_ls" },

    -- Enable rust laguage server
    {
      "rust_analyzer",
      opts = {
        settings = {
          ["rust-analyzer"] = {
            -- Disables running `cargo check` on every save, which is a major performance hog
            -- for large projects. This is often the most important setting.
            checkOnSave = {
              enable = false,
            },
            -- For inlay hints, which can sometimes be a bit heavy.
            -- `rust-analyzer.inlayHints.enable` is a boolean.
            -- `rust-analyzer.inlayHints.lifetimeElisions` and others can be configured separately.
            inlayHints = {
              enable = true,
            },
            -- Controls whether to generate new diagnostics for the entire workspace.
            -- Setting this to `true` can be slow on startup.
            cachePriming = {
              enable = false,
            },
            -- If you have a large workspace with multiple crates, you might want to configure
            -- how `rust-analyzer` handles them.
            cargo = {
              -- Prevents `rust-analyzer` from running build scripts automatically.
              -- This can be a huge time-saver for projects with complex `build.rs` files.
              runBuildScripts = false,
            },
            -- Manages how `rust-analyzer` handles flycheck, the on-the-fly checking of code.
            -- Setting this to false can reduce CPU usage, but you'll get fewer immediate diagnostics.
            check = {
              allTargets = false,
            },
          }
        }
      }
    }
})

------------------------------------------------------------------------
-- Autocommands
------------------------------------------------------------------------
