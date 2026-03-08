-- lua/qmk/keymaps.lua
local M = {}

function M.register(maps)
  local opts = { noremap = true, silent = true }

  if maps.compile then
    vim.keymap.set("n", maps.compile, "<cmd>QMKCompile<cr>",
      vim.tbl_extend("force", opts, { desc = "QMK: Compile" }))
  end

  if maps.compile_select then
    vim.keymap.set("n", maps.compile_select, "<cmd>QMKCompileSelect<cr>",
      vim.tbl_extend("force", opts, { desc = "QMK: Select & Compile" }))
  end

  if maps.open_qf then
    vim.keymap.set("n", maps.open_qf, "<cmd>QMKOpenQF<cr>",
      vim.tbl_extend("force", opts, { desc = "QMK: Open Quickfix" }))
  end
end

return M
