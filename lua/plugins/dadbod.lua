return {
	{
		"vim-dadbod",
		for_cat = "dadbod",
	},
	{
		"vim-dadbod-completion",
		for_cat = "dadbod",
		dep_of = { "vim-dadbod" },
	},
	{
		"vim-dadbod-ui",
		for_cat = "dadbod",
		dep_of = (function()
			local deps = {}

			if nixCats("blink") then
				table.insert(deps, "blink.nvim")
			end

			return deps
		end)(),
		ft = { "sql", "mysql", "plsql" },
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
		before = function()
			-- Enable nerd fonts
			vim.g.db_ui_use_nerd_fonts = 1
		end,
		after = function()
			-- Trigger the load of vim-dadbod to ensure it's available when DBUI is loaded
			require("lze").trigger_load("vim-dadbod")
		end,
	},
}
