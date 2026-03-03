-- Disable arrow keys to enforce hjkl muscle memory
local map = vim.keymap.set
local opts = { noremap = true, silent = true, desc = "Arrow keys disabled" }

for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
  map("n", key, "<Nop>", opts)
  map("i", key, "<Nop>", opts)
  map("v", key, "<Nop>", opts)
end
