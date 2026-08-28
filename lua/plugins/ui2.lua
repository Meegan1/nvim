return {
	{
		"ui2",
		for_cat = "ui2",
		lazy = false,
		-- override load to prevent trying to load from plugin path
		load = function() end,
		after = function()
			require("vim._core.ui2").enable()

			vim.opt.winborder = "rounded"

			local orig_open_floating_preview = vim.lsp.util.open_floating_preview
			---@diagnostic disable-next-line: duplicate-set-field
			vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
				local bufnr, winnr = orig_open_floating_preview(contents, syntax, opts, ...)
				vim.wo[winnr].conceallevel = 3
				vim.wo[winnr].concealcursor = "n"
				return bufnr, winnr
			end
		end,
	},
}
