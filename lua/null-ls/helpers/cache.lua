local next_key = 0

local M = {}

M.cache = {}

--- creates a function that caches the output of a callback, indexed by bufnr
---@param cb function
---@return fun(params: NullLsParams): any
M.by_bufnr = function(cb)
    -- assign next available key, since we just want to avoid collisions
    local key = next_key
    M.cache[key] = {}
    next_key = next_key + 1

    return function(params)
        local bufnr = params.bufnr
        -- if we haven't cached a value yet, get it from cb
        if M.cache[key][bufnr] == nil then
            -- make sure we always store a value so we know we've already called cb
            M.cache[key][bufnr] = cb(params) or false
        end

        return M.cache[key][bufnr]
    end
end

--- creates a function that caches the output of a callback, indexed by the mtime of the files returned by `get_files`
---@param get_files function
---@param cb function
---@return fun(params: NullLsParams): any
M.by_file_mtimes = function(get_files, cb)
    -- assign next available key, since we just want to avoid collisions
    local key = next_key
    M.cache[key] = {}
    next_key = next_key + 1

    return function(params)
        local files = get_files(params)
        table.sort(files)

        local mtimes_key = ""

        for _, file in ipairs(files) do
            local mtime = vim.uv.fs_stat(file).mtime
            mtimes_key = mtimes_key .. "|" .. file .. "|" ..  mtime.sec
        end

        -- if we haven't cached a value yet, get it from cb
        if M.cache[key][mtimes_key] == nil then
            -- make sure we always store a value so we know we've already called cb
            M.cache[key][mtimes_key] = cb(params) or false
        end

        return M.cache[key][mtimes_key]
    end
end

M._reset = function()
    M.cache = {}
end

return M
