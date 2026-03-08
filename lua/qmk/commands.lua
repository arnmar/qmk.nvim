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

function M.register()
  vim.api.nvim_create_user_command("QMKCompile", cmd_compile, {
    desc = "Compile the current QMK keyboard/keymap",
  })

  vim.api.nvim_create_user_command("QMKCompileSelect", cmd_compile_select, {
    desc = "Pick keyboard+keymap interactively, then compile",
  })

  vim.api.nvim_create_user_command("QMKOpenQF", cmd_open_qf, {
    desc = "Open the QMK quickfix window",
  })
end

return M
