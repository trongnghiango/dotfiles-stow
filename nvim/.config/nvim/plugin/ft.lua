-- if a file is a .env or .envrc file, set the filetype to sh
vim.filetype.add({
  filename = {
    [".env"] = "sh",
    [".envrc"] = "sh",
  },
  pattern = {
    ["%.env%.[%w_.-]+"] = "sh", -- .env.local, .env.production
    [".*%.envrc"] = "sh", -- .project.envrc
  },
})
