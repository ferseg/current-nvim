-- autoclose.lua
-- This plugin provides auto-closing functionality for common characters
-- like parentheses, brackets, and quotes.
local M = {}

-- Define the pairs of characters to auto-close
local auto_close_pairs = {
    ['('] = ')',
    ['{'] = '}',
    ['['] = ']',
    ['"'] = '"',
    ["'"] = "'",
    ["`"] = "`",
}

--- Checks if the current character should trigger auto-closing.
-- @param char string The character just inserted.
-- @return boolean True if auto-closing should occur, false otherwise.
local function should_autoclose(char)
    local col = vim.api.nvim_win_get_cursor(0)[2] -- Current column
    local line = vim.api.nvim_buf_get_lines(0, vim.api.nvim_win_get_cursor(0)[1] - 1, vim.api.nvim_win_get_cursor(0)[1], true)[1] or ""
    local char_at_cursor = line:sub(col + 1, col + 1) -- Character immediately after the cursor

    -- If the character to the right of the cursor is already a closing character
    -- and it matches the expected closing character, skip auto-closing.
    -- This prevents `((|))` -> `((|)))`
    if auto_close_pairs[char] and char_at_cursor == auto_close_pairs[char] then
        return false
    end

    -- If it's a quote, check if we are already inside an existing pair.
    -- This helps prevent 'abc' -> ''abc' (where cursor is after first quote)
    if (char == '"' or char == "'" or char == "`") then
        local line_prefix = line:sub(1, col)
        -- Count occurrences of the quote character before the cursor
        local count = 0
        for i = 1, #line_prefix do
            if line_prefix:sub(i, i) == char then
                count = count + 1
            end
        end
        -- If an odd number of quotes, it means we're likely inside a quoted string,
        -- so don't auto-close (unless it's an empty pair like '').
        if count % 2 == 1 and char_at_cursor ~= auto_close_pairs[char] then
             -- Allow auto-closing for empty quotes if cursor is at the very beginning of the line
             if col == 0 then return true end
             -- Or if the character before cursor is whitespace and after cursor is also whitespace or end of line.
             local prev_char = line:sub(col, col)
             if prev_char:match("%s") or col == 0 then
                return true
             end
             return false
        end
    end

    return auto_close_pairs[char] ~= nil
end

--- Handles the auto-closing logic when a character is inserted.
-- This function is attached to 'InsertCharPre'.
-- @param char string The character about to be inserted.
local function autoclose_handler(char)
    if should_autoclose(char) then
        local closing_char = auto_close_pairs[char]
        if closing_char then
            -- Get current cursor position (row, col)
            local cursor = vim.api.nvim_win_get_cursor(0)
            local row, col = cursor[1], cursor[2]

            -- Get the current line content
            local current_line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1] or ""

            -- Construct the new line: prefix + opening char + closing char + suffix
            local new_line = current_line:sub(1, col) .. char .. closing_char .. current_line:sub(col + 1)

            -- Update the buffer with the new line
            vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })

            -- Move cursor back between the inserted chars
            vim.api.nvim_win_set_cursor(0, { row, col + 1 })

            -- Prevent the original character from being inserted by Neovim's default behavior
            -- This makes the 'InsertCharPre' autocommand effectively consume the character
            return true
        end
    end
    return false -- Allow Neovim's default behavior for other characters
end

--- Sets up the auto-closing plugin.
-- @param opts table Configuration options (currently unused but good practice).
function M.setup(opts)
    opts = opts or {}

    -- Create an autogroup for this plugin's autocommands
    local autoclose_augroup = vim.api.nvim_create_augroup("AutoClosePlugin", { clear = true })

    -- Attach the handler to the InsertCharPre event
    -- This event fires *before* the character is inserted into the buffer.
    vim.api.nvim_create_autocmd("InsertCharPre", {
        group = autoclose_augroup,
        callback = function(args)
            -- args.char is the character about to be inserted
            return autoclose_handler(args.char)
        end,
        pattern = "*", -- Apply to all filetypes
        desc = "Auto-close pairs of characters",
    })
end

return M
