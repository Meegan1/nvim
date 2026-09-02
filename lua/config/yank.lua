-- Preserves cursor position after yanking
local preserve_cursor = {}

preserve_cursor.state = {
	cursor = { 0, 0 },
}

-- True while a built-in multicursor session is active in this buffer.
-- Cursors are tracked as extmarks in the "nvim.multicursor" namespace.
local function multicursor_active()
	local ns = vim.api.nvim_get_namespaces()["nvim.multicursor"]
	if not ns then
		return false
	end
	return #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { limit = 1 }) > 0
end

vim.api.nvim_create_autocmd({ "VimEnter", "CursorMoved" }, {
	group = vim.api.nvim_create_augroup("NoMoveYank", { clear = true }),
	callback = function()
		-- Don't save positions replayed by follow-mode (q=)
		if multicursor_active() then
			return
		end
		preserve_cursor.state.cursor = vim.api.nvim_win_get_cursor(0)
	end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
	group = "NoMoveYank",
	callback = function()
		if vim.v.event.operator == "y" and preserve_cursor.state.cursor and not multicursor_active() then
			vim.api.nvim_win_set_cursor(0, preserve_cursor.state.cursor)
		end
	end,
})

-- Highlight yanked text
vim.api.nvim_set_hl(0, "YankHighlight", { link = "Search", default = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
	callback = function()
		pcall(vim.hl.hl_op, { higroup = "YankHighlight", timeout = 200 })
	end,
})

-- Copy and paste to system clipboard
vim.keymap.set({ "n", "x" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
vim.keymap.set({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from clipboard" })
vim.keymap.set({ "n", "x" }, "<leader>P", '"+P', { desc = "Paste from clipboard before" })
