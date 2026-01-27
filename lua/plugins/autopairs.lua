return {
	"nvim-autopairs",
	for_cat = "autopairs",
	event = "InsertEnter",
	after = function()
		require("nvim-autopairs").setup({})
	end,
}
