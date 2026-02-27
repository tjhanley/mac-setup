return {
  -- Ghostty config validation on save
  {
    "isak102/ghostty.nvim",
    ft = "ghostty",
  },

  -- Sync Ghostty themes from Neovim
  {
    "landerson02/ghostty-theme-sync.nvim",
    cmd = "GhosttyTheme",
    opts = {},
  },

  -- Tree-sitter grammar for Ghostty config files
  {
    "bezhermoso/tree-sitter-ghostty",
  },

  -- Add ghostty to treesitter ensure_installed
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "ghostty" },
    },
  },
}
