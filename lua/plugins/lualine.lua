return {
	{
		"copilot-lualine",
		for_cat = "copilot",
	},
	{
		"lualine.nvim",
		for_cat = "lualine",
		after = function()
			vim.o.laststatus = 3
			vim.opt.cmdheight = 0

			if nixCats("copilot") then
				require("lze").trigger_load("copilot-lualine")
			end

			local CodeCompanionStatus = require("lualine.component"):extend()

			CodeCompanionStatus.processing = false
			CodeCompanionStatus.spinner_index = 1

			local spinner_symbols = {
				"⠋",
				"⠙",
				"⠹",
				"⠸",
				"⠼",
				"⠴",
				"⠦",
				"⠧",
				"⠇",
				"⠏",
			}
			local spinner_symbols_len = 10

			-- Initializer
			function CodeCompanionStatus:init(options)
				CodeCompanionStatus.super.init(self, options)

				local group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})

				vim.api.nvim_create_autocmd({ "User" }, {
					pattern = "CodeCompanionRequest*",
					group = group,
					callback = function(request)
						if request.match == "CodeCompanionRequestStarted" then
							self.processing = true
						elseif request.match == "CodeCompanionRequestFinished" then
							self.processing = false
						end
					end,
				})
			end

			-- Function that runs every time statusline is updated
			function CodeCompanionStatus:update_status()
				if self.processing then
					self.spinner_index = (self.spinner_index % spinner_symbols_len) + 1
					return spinner_symbols[self.spinner_index]
				else
					return nil
				end
			end

			require("lualine").setup({
				sections = {
					lualine_a = { "mode" },
					lualine_b = {
						"branch",
						"diff",
						{
							"diagnostics",
							sources = { "nvim_diagnostic" },
							symbols = { error = " ", warn = " ", info = " ", hint = " " },
						},
					},
					lualine_c = {
						{
							function()
								return require("auto-session.lib").current_session_name(true)
							end,
							cond = function()
								return nixCats("auto-session")
							end,
						},
					},
					lualine_x = {
						-- Macro recording
						{
							function()
								return "recording @" .. vim.fn.reg_recording()
							end,
							cond = function()
								return vim.fn.reg_recording() ~= ""
							end,
							color = { fg = "#f8f8f2", bg = "#282a36" },
						},
						{
							CodeCompanionStatus,
							cond = function()
								nixCats("codecompanion")
							end,
						},
						{
							"copilot",
							cond = function()
								return nixCats("copilot")
							end,
						},
						{
							require("minuet.lualine"),
							cond = function()
								return nixCats("minuet")
							end,
							display_name = "provider",
						},
						"filetype",
					},
					lualine_y = { "progress" },
					lualine_z = { "location", "searchcount" },
				},
			})
		end,
	},
}
