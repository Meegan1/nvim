return {
	"project.nvim",
	for_cat = "project",
	after = function()
		require("project").setup({
			patterns = {
				".git",
			},
			fzf_lua = {
				enabled = nixCats("fzf-lua"),
			},
		})

		if nixCats("fzf-lua") then
			local fzf_lua = require("fzf-lua")

			vim.keymap.set("n", "<leader>fp", function()
				local history = require("project.utils.history")
				fzf_lua.fzf_exec(function(cb)
					local results = history.get_recent_projects()
					for _, e in ipairs(results) do
						cb(e)
					end
					cb()
				end, {
					actions = {
						["default"] = {
							function(selected)
								fzf_lua.files({ cwd = selected[1] })
							end,
						},
						["ctrl-d"] = {
							function(selected)
								history.delete_project({ value = selected[1] })
							end,
							fzf_lua.actions.resume,
						},
					},
				})
			end, {
				desc = "fzf-lua: projects",
			})
		elseif nixCats("snacks") then
			local history = require("project.utils.history")
			local Snacks = require("snacks")

			vim.keymap.set("n", "<leader>fp", function()
				local results = history.get_recent_projects()
				local items = {}
				for i, e in ipairs(results) do
					items[i] = { text = e, file = e }
				end

				Snacks.picker.pick({
					source = "projects",
					items = items,
					format = "text",
					confirm = function(picker, item)
						picker:close()
						if item then
							Snacks.picker.files({ cwd = item.file })
						end
					end,
					actions = {
						delete_project = function(picker, item)
							if item then
								history.delete_project({ value = item.file })
								picker:find()
							end
						end,
					},
					win = {
						input = {
							keys = {
								["<c-d>"] = { "delete_project", mode = { "n", "i" } },
							},
						},
					},
				})
			end, {
				desc = "snacks: projects",
			})
		end
	end,
}
