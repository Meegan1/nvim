return {
	{
		"vim-rhubarb",
		for_cat = "git",
		dep_of = { "vim-fugitive" },
	},
	{
		"vim-git",
		for_cat = "git",
		dep_of = { "vim-fugitive" },
	},
	{
		"vim-fugitive",
		for_cat = "git",
		after = function()
			--[[
      --  Remove linematch as it was causing issues with the diff view in fugitive, see:
      --  https://github.com/neovim/neovim/issues/22696#issuecomment-3906586437
      --]]
			vim.opt.diffopt:remove("linematch:40")

			local Fugitive = {}

			local function is_fugitive_buf(bufnr)
				local ok, ft = pcall(vim.api.nvim_buf_get_option, bufnr, "filetype")
				if ok and ft == "fugitive" then
					return true
				end
				local name = vim.api.nvim_buf_get_name(bufnr)
				if name and name:match("^fugitive://") then
					return true
				end
				return false
			end

			function Fugitive.toggle()
				for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
					local bufnr = vim.api.nvim_win_get_buf(win)
					if is_fugitive_buf(bufnr) then
						vim.api.nvim_win_close(win, true)
						return
					end
				end
				-- use the new fugitive command
				vim.cmd("silent G")
			end

			vim.keymap.set("n", "<leader>gs", function()
				Fugitive.toggle()
			end, { noremap = true, silent = true, desc = "Toggle Git status" })

			vim.keymap.set("n", "<leader>gc", function()
				vim.cmd("Git commit")
			end, { noremap = true, silent = true, desc = "Git commit" })

			vim.keymap.set("n", "<leader>gP", function()
				vim.cmd("Git! push")
			end, { noremap = true, silent = true, desc = "Git push" })

			vim.keymap.set("n", "<leader>gp", function()
				vim.cmd("Git! pull")
			end, { noremap = true, silent = true, desc = "Git pull" })

			vim.keymap.set("n", "<leader>gd", function()
				vim.cmd("Gdiffsplit")
			end, { noremap = true, silent = true, desc = "Git diff split" })

			vim.keymap.set("n", "<leader>gl", function()
				vim.cmd("Git log --graph --decorate --all")
			end, { noremap = true, silent = true, desc = "Git log" })

			local _extra_context = {}

			--- Register additional context lines to prepend to commit messages.
			--- Call this from a per-project .nvim.lua file.
			--- @param lines string[]
			function Fugitive.add_commit_context(lines)
				vim.list_extend(_extra_context, lines)
			end

			-- Example usage in .nvim.lua:
			-- if _G.FugitiveAddCommitContext then
			-- 	FugitiveAddCommitContext({
			-- 		"This is a Next.js + TypeScript project",
			-- 		"Ticket format: PROJ-1234 in the footer e.g. 'Refs: PROJ-1234'",
			-- 		"Do not commit changes to generated files under src/generated/",
			-- 	})
			-- end
			--
			-- OR
			--
			-- if _G.FugitiveAddCommitContext then
			--   FugitiveAddCommitContext({
			--     "# - Follow Conventional Commits: <type>(scope): <description>",
			--     "# - Types: feat, fix, chore, docs, refactor, test, style, perf",
			--     "# - Keep subject line under 72 characters",
			--     "# - Use imperative mood (e.g. 'add feature' not 'added feature')",
			--     "# - Read the diff in the current buffer to understand the changes being committed",
			--     "# - Use lowercase types and scopes, description should start with a lowercase letter as well",
			--   })
			-- end
			_G.FugitiveAddCommitContext = Fugitive.add_commit_context

			vim.api.nvim_create_autocmd("User", {
				pattern = "FugitiveEditor",
				callback = function()
					local bufnr = vim.api.nvim_get_current_buf()
					local filename = vim.api.nvim_buf_get_name(bufnr)

					-- Only act on commit message files
					if not filename:match("COMMIT_EDITMSG") then
						return
					end

					local context = {
						"# ---",
						"# Context",
					}

					-- Merge in any project-specific context inside the separator
					for _, line in ipairs(_extra_context) do
						table.insert(context, "# " .. line)
					end

					table.insert(context, "# ---")
					table.insert(context, "#")

					if #_extra_context > 0 then
						vim.api.nvim_buf_set_lines(bufnr, 1, 1, false, context)
					end

					-- Reset Copilot cache so suggestions are fresh for this commit
					local ok, copilot = pcall(require, "copilot.suggestion")
					if ok then
						copilot.dismiss()
					end

					-- Move cursor to line 1 (top, as usual)
					vim.api.nvim_win_set_cursor(0, { 1, 0 })
				end,
			})

			-- Reset project context when changing directory to avoid leaking between projects
			vim.api.nvim_create_autocmd("DirChanged", {
				callback = function()
					_extra_context = {}
				end,
			})
		end,
	},
}
