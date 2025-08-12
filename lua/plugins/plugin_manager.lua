local M = {}

-- A table to store plugin setup configurations keyed by the plugin's module name.
-- This will be processed during Neovim's startup phase.
local plugin_setups = {}

-- Create a single autogroup for managing plugin setups to allow clearing previous ones.
local pack_augroup = vim.api.nvim_create_augroup("PackPluginSetup", { clear = true })

local function setup_keymaps(keymaps)
  -- Handle keymaps if provided in opts.keymaps
  if type(keymaps) ~= "table" then
    return
  end
  for _, keymap_def in ipairs(keymaps) do
    local mode, lhs, rhs, desc, map_opts = nil, nil, nil, nil, nil

    mode = keymap_def.mode or keymap_def[1]
    lhs = keymap_def.lhs or keymap_def[2]
    rhs = keymap_def.rhs or keymap_def[3]
    desc = keymap_def.desc or keymap_def[4]
    map_opts = keymap_def.opts or keymap_def[5]

    -- If there is no keymap basic definition
    if mode == nil or lhs == nil or rhs == nil then
      return
    end

    -- Apply default keymap options if not provided
    map_opts = map_opts or { noremap = true, silent = true }

    -- Add description to map_opts if available (used for :help and other tools)
    if desc then
      map_opts.desc = desc
    end

    -- Safely set the keymap using pcall
    pcall(vim.keymap.set, mode, lhs, rhs, map_opts)
  end
end

--- Tries to require and setup a plugin.
-- This function is intended to be called by the VimEnter autocommand.
-- @param plugin_name string The name of the plugin to require (e.g., 'nvim-treesitter').
-- @param opts table Optional table of options to pass to the plugin's setup function.
local function try_setup_plugin(plugin_name, opts)
    local ok, plugin = pcall(require, plugin_name)
    if ok then
        if plugin and type(plugin.setup) == "function" then
            local setup_ok, setup_result = pcall(plugin.setup, opts or {})
            if setup_ok then
                setup_keymaps(opts.keymaps)
            else
                vim.api.nvim_echo({{
                    "Error: Plugin '" .. plugin_name .. "' setup failed. Error: " .. setup_result, "ErrorMsg"
                }}, true, {})
            end
        else
            -- Plugin loaded, but no setup function found
            vim.api.nvim_echo({{
                "Warning: Plugin '" .. plugin_name .. "' loaded but no 'setup' function found. " ..
                "Ensure the plugin exports a 'setup' function or configure it manually.", "WarningMsg"
            }}, true, {})
        end
    else
        -- Plugin failed to load (e.g., 'require' returned an error)
        vim.api.nvim_echo({{
            "Error: Failed to load plugin '" .. plugin_name .. "'. Error: " .. plugin, "ErrorMsg"
        }}, true, {})
    end
end

-- Autocommand to run all scheduled plugin setups after Neovim has started.
-- This ensures plugins are available via 'require' before attempting to set them up.
vim.api.nvim_create_autocmd("VimEnter", {
    group = pack_augroup,
    callback = function()
        for plugin_name, opts in pairs(plugin_setups) do
            try_setup_plugin(plugin_name, opts)
        end
        -- Clear the stored setups after they have been processed
        plugin_setups = {}
    end,
    once = true, -- Ensure this autocommand only runs once per Neovim session
})

--- Installs a Neovim plugin using vim.pack.add.
-- This function accepts a table as a parameter. The plugin's GitHub path
-- can be specified either with the key 'source' or as the first value
-- in the table (e.g., { "owner/repo" }).
-- It also supports an optional 'event' key for lazy loading the plugin,
-- and an 'opts' table for passing configuration options to the plugin.
-- An optional 'plug_setup_name' can be provided to specify the name
-- used for 'require' if it differs from the last part of the source path.
--
-- @param plugin_info table A table containing the plugin information.
--                          Expected formats:
--                          1. { source = "owner/repo", event = "BufReadPost", opts = { --[[ plugin options ]] }, plug_setup_name = "custom_name" }
--                          2. { "owner/repo", event = "BufReadPost", opts = { --[[ plugin options ]] } }
function M.plugin(plugin_info)
    local plugin_source = nil
    local plugin_event = nil
    local plugin_opts = nil
    local plugin_setup_name = nil
    local plugin_version = nil

    -- Determine the plugin source from the input table
    if plugin_info.source then
        plugin_source = plugin_info.source
    elseif type(plugin_info[1]) == "string" then
        plugin_source = plugin_info[1]
    else
        vim.api.nvim_echo({{
            "Error: Plugin source not found in the provided table. " ..
            "Please use { source = \"owner/repo\" } or { \"owner/repo\" }.", "ErrorMsg"
        }}, true, {})
        return
    end

    -- Check for an optional 'event' key for lazy loading
    if type(plugin_info.event) == "string" then
        plugin_event = plugin_info.event
    end

    -- Check for an optional 'version' key for lazy loading
    if type(plugin_info.version) == "string" then
        plugin_version = vim.version.range(plugin_info.version)
    end

    -- Check for an optional 'opts' key for plugin configuration
    if type(plugin_info.opts) == "table" then
        plugin_opts = plugin_info.opts
    end

    -- Determine the name to use for 'require' (plugin_setup_name)
    if type(plugin_info.plug_setup_name) == "string" and plugin_info.plug_setup_name ~= "" then
        plugin_setup_name = plugin_info.plug_setup_name
    else
        -- Extract the last part of the source path (e.g., "owner/repo-name" -> "repo-name")
        local last_slash_idx = plugin_source:find("[^/]*$")
        if last_slash_idx then
            plugin_setup_name = plugin_source:sub(last_slash_idx)
        else
            plugin_setup_name = plugin_source -- Fallback if no slash in source name
        end
    end

    -- Construct the full GitHub URL for vim.pack.add
    local github_url = "https://github.com/" .. plugin_source

    -- Prepare the plugin definition table for vim.pack.add
    local plugin_definition = { src = github_url }

    -- Add the event for lazy loading if specified
    if plugin_event then
        plugin_definition.event = plugin_event
    end

    if plugin_version then
       plugin_definition.version = plugin_version
    end

    -- Use vim.pack.add to install the plugin
    vim.pack.add({
        plugin_definition
    })

    if plugin_info.skip_setup then
      return
    end
    -- If opts are provided, store them for later setup
    plugin_setups[plugin_setup_name] = plugin_opts or {}
end

function M.no_config_plugins(plugins)
  for _, value in ipairs(plugins) do
    M.plugin({ value })
  end
end

return M -- Handle keymaps if provided in opts.keymaps
