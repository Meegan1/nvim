return {
	{
		"codesnap",
		for_cat = "codesnap",
		lazy = false,
		-- override load to prevent trying to load from plugin path
		load = function() end,
		after = function()
			local CodeSnap = require("modules.codesnap")

			vim.keymap.set({ "n", "x", "v" }, "<leader>cs", function()
				local visual = vim.fn.mode():match("[vV]") ~= nil
				CodeSnap.snapshot({ visual = visual, clipboard = true })
			end, {
				desc = "CodeSnap: Copy selected code to clipboard",
			})
		end,
	},
}
