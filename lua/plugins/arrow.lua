return {
	"arrow.nvim",
	for_cat = "arrow",
	after = function()
		require("arrow").setup({
			show_icons = true,
			leader_key = ";", -- Recommended to be a single key
			buffer_leader_key = "m", -- Per Buffer Mappings
			separate_by_branch = true,
		})
	end,
}
