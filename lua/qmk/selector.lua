-- lua/qmk/selector.lua
-- Interactive keyboard + keymap picker using vim.ui.select
-- Works standalone or with dressing.nvim / telescope-ui-select for a nicer UI.
local M = {}

local function notify(msg, level)
  vim.notify("[qmk] " .. msg, level or vim.log.levels.INFO)
end

--- Recursively find all keymaps under a keyboard directory
---@param kb_path string Absolute path to keyboards/<kb>
---@return string[]
local function find_keymaps(kb_path)
  local keymaps = {}
  local keymaps_dir = kb_path .. "/keymaps"
  if vim.fn.isdirectory(keymaps_dir) == 0 then
    return keymaps
  end

  local handle = vim.loop.fs_scandir(keymaps_dir)
  if not handle then return keymaps end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end
    if type == "directory" then
      table.insert(keymaps, name)
    end
  end

  table.sort(keymaps)
  return keymaps
end

--- Recursively scan for all keyboards (leaf dirs that contain a rules.mk or keymaps/)
---@param base string
---@param prefix string
---@param results string[]
local function scan_keyboards(base, prefix, results)
  local handle = vim.loop.fs_scandir(base)
  if not handle then return end

  local subdirs = {}
  local has_keymaps = vim.fn.isdirectory(base .. "/keymaps") == 1
  local has_rules   = vim.fn.filereadable(base .. "/rules.mk") == 1

  -- A leaf keyboard: has keymaps/ or rules.mk at this level
  if has_keymaps or has_rules then
    if prefix ~= "" then
      table.insert(results, prefix)
    end
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end
    if type == "directory" and name ~= "keymaps" and not name:match("^%.") then
      local child_prefix = prefix == "" and name or (prefix .. "/" .. name)
      scan_keyboards(base .. "/" .. name, child_prefix, results)
    end
  end
end

--- Get list of all keyboards from the QMK path
---@param qmk_path string
---@return string[]
local function get_keyboards(qmk_path)
  local kb_base = qmk_path .. "/keyboards"
  if vim.fn.isdirectory(kb_base) == 0 then
    return {}
  end
  local results = {}
  scan_keyboards(kb_base, "", results)
  table.sort(results)
  return results
end

--- Prompt user to pick keyboard then keymap, then call callback(keyboard, keymap)
---@param qmk_path string
---@param default_kb string|nil
---@param default_km string|nil
---@param callback fun(keyboard: string, keymap: string)
function M.pick(qmk_path, default_kb, default_km, callback)
  notify("Scanning keyboards…")

  -- Run keyboard scan in a deferred call so the notification renders first
  vim.defer_fn(function()
    local keyboards = get_keyboards(qmk_path)

    if #keyboards == 0 then
      notify("No keyboards found in " .. qmk_path, vim.log.levels.ERROR)
      return
    end

    -- Bubble the last-used keyboard to the top
    if default_kb then
      local idx = nil
      for i, kb in ipairs(keyboards) do
        if kb == default_kb then idx = i; break end
      end
      if idx then
        table.remove(keyboards, idx)
        table.insert(keyboards, 1, default_kb)
      end
    end

    vim.ui.select(keyboards, {
      prompt = "QMK › Select keyboard:",
      format_item = function(item)
        return item == default_kb and ("★ " .. item) or item
      end,
    }, function(keyboard)
      if not keyboard then return end

      local kb_path = qmk_path .. "/keyboards/" .. keyboard
      local keymaps = find_keymaps(kb_path)

      if #keymaps == 0 then
        notify("No keymaps found for " .. keyboard, vim.log.levels.WARN)
        return
      end

      -- Bubble last-used keymap
      if default_km then
        local idx = nil
        for i, km in ipairs(keymaps) do
          if km == default_km then idx = i; break end
        end
        if idx then
          table.remove(keymaps, idx)
          table.insert(keymaps, 1, default_km)
        end
      end

      vim.ui.select(keymaps, {
        prompt = string.format("QMK › %s › Select keymap:", keyboard),
        format_item = function(item)
          return item == default_km and ("★ " .. item) or item
        end,
      }, function(keymap)
        if not keymap then return end
        callback(keyboard, keymap)
      end)
    end)
  end, 10)
end

return M
