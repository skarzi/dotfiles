vim.api.nvim_create_user_command("MakeTags", "!ctags -R .", { nargs = 0 })
