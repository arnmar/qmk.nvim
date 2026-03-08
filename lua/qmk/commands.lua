-- lua/qmk/commands.lua
local M = {}

local function get_cfg()
  return require("qmk").config
end

local function do_compile(keyboard, keymap)
  local cfg = get_cfg()
  local cache = require("qmk.cache")

  -- Persist selection
  cfg.keyboard = keyboard
  cfg.keymap   = keymap
  cache.save(keyboard, keymap)

  require("qmk.compile").run(keyboard, keymap, cfg)
end

-- Compile using the last-known (or config-set) keyboard/keymap.
-- If none is stored, fall through to interactive selection.
local function cmd_compile()
  local cfg = get_cfg()
  if cfg.keyboard and cfg.keymap then
    do_compile(cfg.keyboard, cfg.keymap)
  else
    vim.notify("[qmk] No keyboard/keymap set — opening selector", vim.log.levels.WARN)
    cmd_compile_select()
  end
end

-- Always open the interactive picker, then compile.
function cmd_compile_select()
  local cfg = get_cfg()
  require("qmk.selector").pick(
    cfg.qmk_path,
    cfg.keyboard,
    cfg.keymap,
    do_compile
  )
end

-- Re-open the quickfix window.
local function cmd_open_qf()
  vim.cmd("copen")
end

-- Show history menu: pick a previous keyboard/keymap and compile it.
local function cmd_history()
  local cache = require("qmk.cache")
  local history = cache.history()

  if #history == 0 then
    vim.notify("[qmk] No compile history yet", vim.log.levels.WARN)
    return
  end

  -- Build display labels
  local items = {}
  for i, entry in ipairs(history) do
    local prefix = i == 1 and "★ " or "  "
    table.insert(items, {
      label   = string.format("%s%s  [%s]", prefix, entry.keyboard, entry.keymap),
      keyboard = entry.keyboard,
      keymap   = entry.keymap,
    })
  end

  -- Append a "Clear history" option at the bottom
  table.insert(items, { label = "✕  Clear history", clear = true })

  vim.ui.select(items, {
    prompt = "QMK › Recent keyboards:",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end

    if choice.clear then
      -- Wipe history by saving current entry only (or nothing)
      local cfg = get_cfg()
      local data_path = vim.fn.stdpath("data") .. "/qmk_nvim_cache.json"
      local f = io.open(data_path, "w")
      if f then
        f:write(vim.fn.json_encode({
          keyboard = cfg.keyboard,
          keymap   = cfg.keymap,
          history  = {},
        }))
        f:close()
      end
      vim.notify("[qmk] History cleared", vim.log.levels.INFO)
      return
    end

    do_compile(choice.keyboard, choice.keymap)
  end)
end

function M.register()
  vim.api.nvim_create_user_command("QMKCompile", cmd_compile, {
    desc = "Compile the current QMK keyboard/keymap",
  })

  vim.api.nvim_create_user_command("QMKCompileSelect", cmd_compile_select, {
    desc = "Pick keyboard+keymap interactively, then compile",
  })

  vim.api.nvim_create_user_command("QMKHistory", cmd_history, {
    desc = "Pick from recently compiled keyboards and compile",
  })

  vim.api.nvim_create_user_command("QMKOpenQF", cmd_open_qf, {
    desc = "Open the QMK quickfix window",
  })
end

return M
