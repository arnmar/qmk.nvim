-- lua/qmk/cache.lua
-- Persists last used keyboard/keymap + a history list to disk.
local M = {}

local HISTORY_MAX = 10
local cache_path = vim.fn.stdpath("data") .. "/qmk_nvim_cache.json"

local function read()
  local f = io.open(cache_path, "r")
  if not f then return {} end
  local raw = f:read("*a")
  f:close()
  if not raw or raw == "" then return {} end
  local ok, data = pcall(vim.fn.json_decode, raw)
  return (ok and type(data) == "table") and data or {}
end

local function write(data)
  local ok, encoded = pcall(vim.fn.json_encode, data)
  if not ok then return end
  local f = io.open(cache_path, "w")
  if f then f:write(encoded); f:close() end
end

--- Save a keyboard/keymap as the most recent entry and prepend it to history.
---@param keyboard string
---@param keymap string
function M.save(keyboard, keymap)
  local data = read()

  data.keyboard = keyboard
  data.keymap   = keymap

  -- Maintain history: most recent first, no duplicates
  local history = data.history or {}
  local entry = keyboard .. ":" .. keymap

  for i, v in ipairs(history) do
    if v == entry then table.remove(history, i); break end
  end

  table.insert(history, 1, entry)

  while #history > HISTORY_MAX do table.remove(history) end

  data.history = history
  write(data)
end

--- Load last-used keyboard/keymap.
---@return {keyboard: string, keymap: string}|nil
function M.load()
  local data = read()
  if data.keyboard and data.keymap then
    return { keyboard = data.keyboard, keymap = data.keymap }
  end
  return nil
end

--- Load history as a list of {keyboard, keymap} tables, most recent first.
---@return {keyboard: string, keymap: string}[]
function M.history()
  local data = read()
  local result = {}
  for _, entry in ipairs(data.history or {}) do
    local kb, km = entry:match("^(.+):(.+)$")
    if kb and km then
      table.insert(result, { keyboard = kb, keymap = km })
    end
  end
  return result
end

--- Remove a specific entry from history.
---@param keyboard string
---@param keymap string
function M.remove(keyboard, keymap)
  local data = read()
  local entry = keyboard .. ":" .. keymap
  local history = data.history or {}
  for i, v in ipairs(history) do
    if v == entry then table.remove(history, i); break end
  end
  data.history = history
  write(data)
end

return M
