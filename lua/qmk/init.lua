-- lua/qmk/init.lua
local M = {}

---@class QmkConfig
---@field qmk_path string Path to QMK firmware directory
---@field keyboard string|nil Last used keyboard
---@field keymap string|nil Last used keymap
---@field make_jobs number Parallel make jobs (0 = auto)
---@field auto_open_qf boolean Auto-open quickfix on errors
---@field keymaps table<string, string> Key mappings

M.config = {
  qmk_path = vim.fn.expand("~/qmk_firmware"),
  keyboard = nil,
  keymap = nil,
  make_jobs = 0,
  auto_open_qf = true,
  keymaps = {
    compile        = "<leader>qc",
    compile_select = "<leader>qs",
    open_qf        = "<leader>qq",
  },
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Try to load persisted keyboard/keymap from cache
  local cache = require("qmk.cache")
  local saved = cache.load()
  if saved then
    M.config.keyboard = M.config.keyboard or saved.keyboard
    M.config.keymap   = M.config.keymap   or saved.keymap
  end

  require("qmk.commands").register()
  require("qmk.keymaps").register(M.config.keymaps)
end

return M
