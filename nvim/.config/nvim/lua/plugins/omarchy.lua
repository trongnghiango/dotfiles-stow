---@type LazySpec
return {
  -- ==========================================================================
  -- Omarchy Curated Theme Registry (Lazy Loaded)
  -- ==========================================================================
  {
    "ribru17/bamboo.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    lazy = true,
    priority = 1000,
  },
  {
    "bjarneo/ethereal.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "bjarneo/hackerman.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "bjarneo/vantablack.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "bjarneo/white.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "neanias/everforest-nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "kepano/flexoki-neovim",
    name = "flexoki",
    lazy = true,
    priority = 1000,
  },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "tahayvr/matteblack.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "gthelding/monokai-pro.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "EdenEast/nightfox.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    priority = 1000,
  },
  {
    "ficcdaf/ashen.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "OldJobobo/miasma.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "OldJobobo/retro-82.nvim",
    lazy = true,
    priority = 1000,
  },
  {
    "omacom-io/lumon.nvim",
    lazy = true,
    priority = 1000,
  },

  -- ==========================================================================
  -- Omarchy Hot-Reload & Event Listener
  -- ==========================================================================
  {
    name = "omarchy-integration",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    priority = 1000,
    config = function()
      -- Listen for LazyReload event from external Omarchy theme switcher
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyReload",
        callback = function()
          vim.schedule(function()
            -- Redraw and reapply transparency
            vim.cmd("redraw!")
            require("core.transparency").apply()
          end)
        end,
      })
    end,
  },
}
