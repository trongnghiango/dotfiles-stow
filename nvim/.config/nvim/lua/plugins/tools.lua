-- Tools: Notes, file creation, debugging, and custom utilities
return {
  -- ═════════════════════════════════════════════════════════════════════════════
  -- nvim-dap: Debug Adapter Protocol
  -- ═════════════════════════════════════════════════════════════════════════════
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "mfussenegger/nvim-dap-python",
      "mfussenegger/nvim-dap-rust",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      -- Auto open/close UI
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- Python
      require("dap-python").setup("python")

      -- Rust (requires codelldb)
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = { command = "codelldb", args = { "--port", "${port}" } },
      }
      dap.configurations.rust = {
        {
          type = "codelldb",
          request = "launch",
          name = "Debug",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      -- Keymaps
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP Continue" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP Step Over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP Step Into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "DAP Step Out" })
      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "DAP Toggle Breakpoint" })
      vim.keymap.set("n", "<leader>B", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "DAP Conditional Breakpoint" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP UI Toggle" })
    end,
  },

  -- ══════════════════════════════════════════════════════════════════════════════
  -- Notes management
  -- ═════════════════════════════════════════════════════════════════════════════
  -- {
  --   "adibhanna/nvim-notes",
  --   dependencies = { "MunifTanjim/nui.nvim" },
  --   config = function()
  --     require("nvim-notes").setup({
  --       vault_path = "~/notes",
  --     })
  --   end,
  -- },

  -- -- ═════════════════════════════════════════════════════════════════════════════
  -- -- Quick file creation
  -- -- ════════════════════════════════════════════════════════════════════════════
  -- {
  --   "adibhanna/nvim-newfile.nvim",
  --   dependencies = { "MunifTanjim/nui.nvim" },
  --   config = function()
  --     require("nvim-newfile").setup({
  --       notifications = {
  --         enabled = false,
  --       },
  --     })
  --   end,
  -- },
}