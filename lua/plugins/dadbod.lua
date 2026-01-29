return {
	{
		"vim-dadbod",
		for_cat = "dadbob",
		dep_of = { "vim-dadbod-ui" },
	},
	{
		"vim-dadbod-completion",
		for_cat = "dadbob",
		dep_of = { "vim-dadbod-ui" },
	},
	{
		"vim-dadbod-ui",
		cmd = {
			"DBUI",
			"DBUIToggle",
			"DBUIAddConnection",
			"DBUIFindBuffer",
		},
		keys = {
			{
				"<leader>D",
				function()
					vim.cmd("DBUIToggle")
				end,
				desc = "Toggle DBUI",
			},
		},
		after = function()
			-- Your DBUI configuration
			vim.g.db_ui_use_nerd_fonts = 1
		end,
	},
}
