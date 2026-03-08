-- lua/qmk/cache.lua
-- Persists last used keyboard/keymap to stdpath("data")/qmk.json
local M = {}

local cache_path = vim.fn.stdpath("data") .. "/qmk_nvim_cache.json"

function M.save(keyboard, keymap)
  local ok, encoded = pcall(vim.fn.json_encode, { keyboard = keyboard, keymap = keymap })
  if not ok then return end
  local f = io.open(cache_path, "w")
  if f then
    f:write(encoded)
    f:close()
  end
end

---@return {keyboard: string, keymap: string}|nil
function M.load()
  local f = io.open(cache_path, "r")
  if not f then return nil end
  local raw = f:read("*a")
  f:close()
  if not raw or raw == "" then return nil end
  local ok, data = pcall(vim.fn.json_decode, raw)
  if ok and type(data) == "table" then
    return data
  end
  return nil
end

return M
