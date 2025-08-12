-- Create a dedicated autogroup for LSP keymaps to ensure proper clearing
local lsp_keymaps_augroup = vim.api.nvim_create_augroup("LspKeymaps", { clear = true })

-- Define your default LSP keymaps here
-- Each entry is a table with 'mode', 'lhs', 'rhs', and an optional 'desc'.
-- These are the common LSP functions you'd want to bind.
local default_lsp_keymaps = {
    -- Navigation and Information
    { mode = "n", lhs = "gd", rhs = "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "LSP: Go to Definition" },
    { mode = "n", lhs = "gD", rhs = "<cmd>lua vim.lsp.buf.declaration()<CR>", desc = "LSP: Go to Declaration" },
    { mode = "n", lhs = "gi", rhs = "<cmd>lua vim.lsp.buf.implementation()<CR>", desc = "LSP: Go to Implementation" },
    { mode = "n", lhs = "gr", rhs = "<cmd>lua vim.lsp.buf.references()<CR>", desc = "LSP: Find References" },
    { mode = "n", lhs = "K", rhs = "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "LSP: Show Hover Documentation" },
    { mode = "n", lhs = "<C-k>", rhs = "<cmd>lua vim.lsp.buf.signature_help()<CR>", desc = "LSP: Show Signature Help" },

    -- Actions and Diagnostics
    { mode = "n", lhs = "<leader>ca", rhs = "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "LSP: Run Code Action" },
    { mode = "n", lhs = "<leader>rn", rhs = "<cmd>lua vim.lsp.buf.rename()<CR>", desc = "LSP: Rename Symbol" },
    { mode = "n", lhs = "[d", rhs = "<cmd>lua vim.diagnostic.goto_prev()<CR>", desc = "LSP: Previous Diagnostic" },
    { mode = "n", lhs = "]d", rhs = "<cmd>lua vim.diagnostic.goto_next()<CR>", desc = "LSP: Next Diagnostic" },
    { mode = "n", lhs = "<leader>F", rhs = "<cmd>lua vim.lsp.buf.format()<CR>", desc = "LSP: Format Document" },
}

--- Function to set LSP keymaps for a specific buffer.
-- This function is called by the LspAttach autocommand.
-- @param bufnr number The buffer number to apply keymaps to.
local function set_lsp_buffer_keymaps(bufnr)
    -- Loop through each defined LSP keymap
    for _, keymap_def in ipairs(default_lsp_keymaps) do
        local mode = keymap_def.mode
        local lhs = keymap_def.lhs
        local rhs = keymap_def.rhs
        local desc = keymap_def.desc
        -- Default keymap options, ensuring it's buffer-local
        local map_opts = { noremap = true, silent = true, buffer = bufnr }

        if desc then
            map_opts.desc = desc
        end

        -- Safely set the keymap
        local ok, err = pcall(vim.keymap.set, mode, lhs, rhs, map_opts)
        if not ok then
            vim.api.nvim_echo({{
                "Error setting LSP keymap for buffer " .. bufnr .. ": " .. lhs .. " -> " .. rhs .. ". Error: " .. err, "ErrorMsg"
            }}, true, {})
        end
    end
end

-- Create the LspAttach autocommand
-- This autocommand triggers when an LSP client successfully attaches to a buffer.
vim.api.nvim_create_autocmd("LspAttach", {
    group = lsp_keymaps_augroup,
    callback = function(args)
        -- `args.buf` contains the buffer number where LSP attached
        set_lsp_buffer_keymaps(args.buf)
    end,
    desc = "Set buffer-local LSP keymaps on LspAttach",
})

local M = {}

--- Function that sets up an lsp server
-- @param config table
local setup_lsp = function (config)
  -- Input validation
  if type(config) ~= "table" then
    vim.api.nvim_echo({{
      "Error: Invalid input. Expected a table for plugin_info.", "ErrorMsg"
    }}, true, {})
    return
  end

  local lsp_name = config.name or config[1]
  local lsp_settings = config.opts or {}

  local lsp_capabilities = vim.lsp.protocol.make_client_capabilities()
  local blink_capabilities = require("blink.cmp").get_lsp_capabilities(lsp_capabilities)
  lsp_settings.capabilities = blink_capabilities
  vim.lsp.config(lsp_name, lsp_settings)
  vim.lsp.enable(lsp_name)
end

function M.setup(servers)
  if type(servers) ~= "table" then
    return
  end

  for index, server in ipairs(servers) do
    if type(server) ~= "table" then
      vim.api.nvim_echo({{
        "Error setting LSP server at " .. index .. " since it is not a table", "ErrorMsg"
      }}, true, {})
      return
    end
    setup_lsp(server)
  end
end

return M
