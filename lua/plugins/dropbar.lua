return {
	"dropbar.nvim",
	after = function()
		local utils = require("dropbar.utils")
		local api = require("dropbar.api")

		require("dropbar").setup({
			bar = {
				enable = function(buf, win, _)
					if
						not vim.api.nvim_buf_is_valid(buf)
						or not vim.api.nvim_win_is_valid(win)
						or vim.fn.win_gettype(win) ~= ""
						or vim.wo[win].winbar ~= ""
						or vim.bo[buf].ft == "help"
						or vim.bo[buf].buftype == "terminal"
					then
						return false
					end

					local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
					if stat and stat.size > 1024 * 1024 then
						return false
					end

					return vim.bo[buf].ft == "markdown"
						or vim.bo[buf].ft == "oil" -- enable in oil buffers
						or pcall(vim.treesitter.get_parser, buf)
						or not vim.tbl_isempty(vim.lsp.get_clients({
							bufnr = buf,
							method = "textDocument/documentSymbol",
						}))
				end,

				sources = function(buf, _)
					local sources = require("dropbar.sources")

					if vim.bo[buf].buftype == "terminal" then
						return {
							sources.terminal,
						}
					end

					return {
						sources.path,
						path = {
							relative_to = function(buf, win)
								-- Show full path in oil or fugitive buffers
								local bufname = vim.api.nvim_buf_get_name(buf)
								if vim.startswith(bufname, "oil://") then
									local root = bufname:gsub("^%S+://", "", 1)
									while root and root ~= vim.fs.dirname(root) do
										root = vim.fs.dirname(root)
									end
									return root
								end

								local ok, cwd = pcall(vim.fn.getcwd, win)
								return ok and cwd or vim.fn.getcwd()
							end,
						},
					}
				end,
			},
			menu = {
				preview = false,
				keymaps = {
					["l"] = function()
						local menu = utils.menu.get_current()
						if not menu then
							return
						end
						local cursor = vim.api.nvim_win_get_cursor(menu.win)
						local component = menu.entries[cursor[1]]:first_clickable(cursor[2])
						if component then
							menu:click_on(component, nil, 1, "l")
						end
					end,
					["h"] = "<C-w>q",
				},
			},
		})

		vim.keymap.set("n", "<leader>dp", function()
			api.pick()
		end, { noremap = true, silent = true, desc = "Pick dropbar" })
	end,
}
