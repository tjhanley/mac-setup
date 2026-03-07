-- Repo-managed Neovim options loaded from LazyVim's options.lua.
-- Keep this file additive to avoid conflicts with the LazyVim starter.

-- ~/.secrets and similar files get shell syntax highlighting
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { "*.secrets", ".secrets" },
  callback = function() vim.bo.filetype = "sh" end,
})

-- Disable unused providers
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
