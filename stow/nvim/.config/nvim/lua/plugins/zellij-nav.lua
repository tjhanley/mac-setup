-- Seamless Ctrl+h/j/k/l navigation between Neovim splits and Zellij panes.
-- Pairs with the vim-zellij-navigator + zellij-autolock plugins configured in
-- stow/zellij/.config/zellij/config.kdl. When the cursor is at the edge of the
-- Neovim split, these commands hand focus back to Zellij (crossing tabs on
-- left/right to mirror the Zellij-side move_focus_or_tab bindings).
return {
  "swaits/zellij-nav.nvim",
  lazy = true,
  event = "VeryLazy",
  opts = {},
  keys = {
    { "<c-h>", "<cmd>ZellijNavigateLeftTab<cr>", { silent = true, desc = "Navigate left (Zellij)" } },
    { "<c-j>", "<cmd>ZellijNavigateDown<cr>", { silent = true, desc = "Navigate down (Zellij)" } },
    { "<c-k>", "<cmd>ZellijNavigateUp<cr>", { silent = true, desc = "Navigate up (Zellij)" } },
    { "<c-l>", "<cmd>ZellijNavigateRightTab<cr>", { silent = true, desc = "Navigate right (Zellij)" } },
  },
}
