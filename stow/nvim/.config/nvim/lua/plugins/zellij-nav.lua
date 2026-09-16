-- Seamless Ctrl+h/j/k/l navigation between Neovim splits and Zellij panes.
-- Pairs with the vim-zellij-navigator + zellij-autolock plugins configured in
-- stow/zellij/.config/zellij/config.kdl. When the cursor is at the edge of the
-- Neovim split, these commands hand focus back to Zellij (crossing tabs on
-- left/right to mirror the Zellij-side move_focus_or_tab bindings).
--
-- Only active inside Zellij. In a Herdr pane these commands would shell out to
-- a `zellij` that isn't running, so the spec is skipped and LazyVim's own
-- <C-h/j/k/l> -> <C-w>h/j/k/l window maps stay in effect; Herdr pane focus
-- lives on ctrl+alt+h/j/k/l instead (stow/herdr/.config/herdr/config.toml).
-- `cond` rather than `enabled` so lazy.nvim keeps the plugin installed.
return {
  "swaits/zellij-nav.nvim",
  lazy = true,
  cond = function()
    return vim.env.ZELLIJ ~= nil
  end,
  event = "VeryLazy",
  opts = {},
  keys = {
    { "<c-h>", "<cmd>ZellijNavigateLeftTab<cr>", { silent = true, desc = "Navigate left (Zellij)" } },
    { "<c-j>", "<cmd>ZellijNavigateDown<cr>", { silent = true, desc = "Navigate down (Zellij)" } },
    { "<c-k>", "<cmd>ZellijNavigateUp<cr>", { silent = true, desc = "Navigate up (Zellij)" } },
    { "<c-l>", "<cmd>ZellijNavigateRightTab<cr>", { silent = true, desc = "Navigate right (Zellij)" } },
  },
}
