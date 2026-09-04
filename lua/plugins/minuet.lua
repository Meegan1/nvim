return {
	"minuet-ai.nvim",
	for_cat = "minuet",
	after = function()
		require("minuet").setup({
			provider = "codestral",
			request_timeout = 2.5,
			throttle = 350, -- Increase to reduce costs and avoid rate limits
			debounce = 150, -- Increase to reduce costs and avoid rate limits
			provider_options = {
				codestral = {
					optional = {
						max_tokens = 256,
						stop = { "\n\n" },
					},
				},
				openai_compatible = {
					api_key = "OPENROUTER_API_KEY",
					end_point = "https://openrouter.ai/api/v1/chat/completions",
					model = "deepseek/deepseek-v4-flash",
					name = "Openrouter",
					optional = {
						max_tokens = 56,
						top_p = 0.9,
						provider = {
							-- Prioritize throughput for faster completion
							sort = "throughput",
						},
						-- disable thinking to avoid first token latency
						reasoning_effort = "none",
					},
				},
			},

			virtualtext = {
				auto_trigger_ft = { "*" },
				auto_trigger_ignore_ft = { "codecompanion" },
				keymap = {
					accept = "<Tab>",
					accept_line = "<C-S-l>",
					dismiss = "<S-Esc>",
				},
				show_on_completion_menu = true,
			},
		})
	end,
}
