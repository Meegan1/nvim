return {
	{
		"nui.nvim",
		for_cat = "noice",
	},
	{
		"noice.nvim",
		for_cat = "noice",
		event = "DeferredUIEnter",
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		after = function()
			-- HACK: noice shows messages from before it was enabled,
			-- but this is not ideal when Lazy is installing plugins,
			-- so clear the messages in this case.
			if vim.o.filetype == "lazy" then
				vim.cmd([[messages clear]])
			end

			require("noice").setup({
				cmdline = {
					view = (function()
						if type(nixCats("options.noice.cmdline.view")) == "string" then
							return nixCats("options.noice.cmdline.view")
						else
							return "cmdline_popup"
						end
					end)(),
				},
				lsp = {
					-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
					},
					hover = {
						silent = true,
					},
				},
				-- you can enable a preset for easier configuration
				presets = {
					bottom_search = true, -- use a classic bottom cmdline for search
					command_palette = true, -- position the cmdline and popupmenu together
					long_message_to_split = true, -- long messages will be sent to a split
					inc_rename = false, -- enables an input dialog for inc-rename.nvim
					lsp_doc_border = true, -- add a border to hover docs and signature help
				},
				notify = {
					enabled = false, -- using snacks.nvim instead
				},
				messages = {
					view = "messages",
					view_errors = "messages",
					view_warn = "messages",
				},
			})
		end,
	},
}
