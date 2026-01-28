return {
	"copilot.lua",
	for_cat = "copilot",
	cmd = "Copilot",
	event = "InsertEnter",
	after = function()
		local logger = require("copilot.logger")

		local allowed_buflisted_filetypes = {
			"gitcommit",
		}

		require("copilot").setup({
			suggestion = {
				auto_trigger = true,
				keymap = {
					accept = false,
					accept_word = "<C-l>",
					accept_line = "<C-S-l>",
					next = false,
					prev = false,
					dismiss = false,
				},
			},
			filetypes = {
				yaml = true,
				markdown = true,
				gitcommit = true,
			},
			should_attach = function(_, bufname)
				if not vim.bo.buflisted then
					if vim.tbl_contains(allowed_buflisted_filetypes, vim.bo.ft) then
						return true
					end

					logger.debug("not attaching, buffer is not 'buflisted'")
					return false
				end

				if vim.bo.buftype ~= "" then
					logger.debug("not attaching, buffer 'buftype' is " .. vim.bo.buftype)
					return false
				end

				return true
			end,
		})

		vim.keymap.set("i", "<Tab>", function()
			if require("copilot.suggestion").is_visible() then
				require("copilot.suggestion").accept()
			else
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
			end
		end, {
			silent = true,
		})

		vim.keymap.set("i", "<S-Esc>", function()
			if require("copilot.suggestion").is_visible() then
				require("copilot.suggestion").dismiss()
			else
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Esc>", true, false, true), "n", false)
			end
		end, {
			silent = true,
		})
	end,
}
