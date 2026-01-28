return {
	"gitsigns.nvim",
	for_cat = "git",
	after = function()
		require("gitsigns").setup({
			on_attach = function(bufnr)
				local gitsigns = require("gitsigns")

				local function map(mode, lhs, rhs, _opts)
					local opts = _opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, lhs, rhs, opts)
				end

				-- Actions
				map("n", "<leader>hs", gitsigns.stage_hunk, {
					desc = "Stage hunk",
				})
				map("n", "<leader>hr", gitsigns.reset_hunk, {
					desc = "Reset hunk",
				})
				map("v", "<leader>hs", function()
					gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, {
					desc = "Stage hunk",
				})
				map("v", "<leader>hr", function()
					gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, {
					desc = "Reset hunk",
				})
				map("n", "<leader>hS", gitsigns.stage_buffer, {
					desc = "Stage buffer",
				})
				map("n", "<leader>hu", gitsigns.undo_stage_hunk, {
					desc = "Undo stage hunk",
				})
				map("n", "<leader>hR", gitsigns.reset_buffer, {
					desc = "Reset buffer",
				})
				map("n", "<leader>hp", gitsigns.preview_hunk, {
					desc = "Preview hunk",
				})
				map("n", "<leader>hb", function()
					gitsigns.blame_line({ full = true })
				end, {
					desc = "Blame line",
				})
				vim.keymap.set("n", "<leader>gb", function()
					gitsigns.blame()
				end, { desc = "Git blame" })
				map("n", "<leader>tb", gitsigns.toggle_current_line_blame, {
					desc = "Toggle current line blame",
				})
				map("n", "<leader>hd", gitsigns.diffthis, {
					desc = "Diff this",
				})
				map("n", "<leader>hD", function()
					gitsigns.diffthis("~")
				end, {
					desc = "Diff this (cached)",
				})
				map("n", "<leader>td", gitsigns.toggle_deleted, {
					desc = "Toggle deleted",
				})

				-- Text object
				map({ "o", "x" }, "ih", function()
					gitsigns.select_hunk()
				end, {
					desc = "In hunk",
				})

				if nixCats("which-key") then
					local wk = require("which-key")

					wk.add({
						nowait = false,
						{
							"<leader>h",
							group = "Git Hunk",
							mode = { "n", "v" },
						},
					})
				end
			end,

			current_line_blame = true,
		})
	end,
}
