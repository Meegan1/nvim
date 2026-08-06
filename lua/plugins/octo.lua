return {
	"octo.nvim",
	for_cat = "github",
	after = function()
		require("octo").setup({
			picker = "snacks",
		})

		local Job = require("plenary.job")

		vim.api.nvim_create_user_command("CheckoutIssue", function(opts)
			-- get the issue id from argument or popup
			local issue_id = opts.args ~= "" and opts.args or vim.fn.input("Issue ID: ")

			-- check if issue id is not empty
			if issue_id ~= "" then
				-- Notify the user that the branch creation is starting
				vim.notify("Creating branch for issue " .. issue_id, "info", { title = "Octo" })

				-- run gh issue develop <issue_id> --checkout
				Job:new({
					command = "gh",
					args = { "issue", "develop", issue_id, "--checkout", "--base", "main" },
					on_exit = function(j, return_val)
						if return_val == 0 then
							vim.notify("Checked out issue", "info", { title = "Octo" })
						else
							vim.notify(vim.inspect(j:stderr_result()), "error", { title = "Octo" })
							vim.notify("Failed to checkout issue", "error", { title = "Octo" })
						end
					end,
				}):start()
			end
		end, {
			desc = "Checkout an issue",
			nargs = "?",
		})
	end,
	beforeAll = function(plugin)
		-- check if gh is installed
		plugin.enabled = vim.fn.executable("gh") == 1
	end,
}
