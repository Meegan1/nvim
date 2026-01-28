return {
	{
		"vim-rhubarb",
		for_cat = "git",
		dep_of = { "vim-fugitive" },
	},
	{
		"vim-git",
		for_cat = "git",
		dep_of = { "vim-fugitive" },
	},
	{
		"vim-fugitive",
		for_cat = "git",
		after = function()
			local Fugitive = {}

			local function is_fugitive_buf(bufnr)
				local ok, ft = pcall(vim.api.nvim_buf_get_option, bufnr, "filetype")
				if ok and ft == "fugitive" then
					return true
				end
				local name = vim.api.nvim_buf_get_name(bufnr)
				if name and name:match("^fugitive://") then
					return true
				end
				return false
			end

			function Fugitive.toggle()
				for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
					local bufnr = vim.api.nvim_win_get_buf(win)
					if is_fugitive_buf(bufnr) then
						vim.api.nvim_win_close(win, true)
						return
					end
				end
				-- use the new fugitive command
				vim.cmd("silent G")
			end

			vim.keymap.set("n", "<leader>gs", function()
				Fugitive.toggle()
			end, { noremap = true, silent = true, desc = "Toggle Git status" })

			vim.keymap.set("n", "<leader>gc", function()
				vim.cmd("Git commit")
			end, { noremap = true, silent = true, desc = "Git commit" })

			vim.keymap.set("n", "<leader>gP", function()
				vim.cmd("Git! push")
			end, { noremap = true, silent = true, desc = "Git push" })

			vim.keymap.set("n", "<leader>gp", function()
				vim.cmd("Git! pull")
			end, { noremap = true, silent = true, desc = "Git pull" })

			vim.keymap.set("n", "<leader>gd", function()
				vim.cmd("Gdiffsplit")
			end, { noremap = true, silent = true, desc = "Git diff split" })

			vim.keymap.set("n", "<leader>gl", function()
				vim.cmd("Git log --graph --decorate --all")
			end, { noremap = true, silent = true, desc = "Git log" })
		end,
	},
}
