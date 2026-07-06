return {
	"grug-far.nvim",
	for_cat = "grug-far",
	cmd = "GrugFar",
	keys = {
		{
			"<leader>ff",
			function()
				local grug = require("grug-far")
				local is_open = grug.is_instance_open("default")

				if is_open then
					grug.close_instance("default")
				else
					grug.open({
						transient = true,
						instanceName = "default",
					})
				end
			end,
			mode = { "n", "v" },
			desc = "Search and Replace",
		},
	},
	after = function()
		require("grug-far").setup({
			headerMaxWidth = 80,
			startInInsertMode = false,

			prefills = {
				flags = "-u --hidden --glob=!{.git,node_modules,.nx,.next,dist,coverage}",
			},
		})
	end,
}
