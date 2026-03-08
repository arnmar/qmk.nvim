-- qmk.nvim entry point
if vim.g.loaded_qmk then
  return
end
vim.g.loaded_qmk = 1

require("qmk").setup()
