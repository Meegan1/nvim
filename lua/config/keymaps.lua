vim.keymap.set({
	"i",
}, "<Char-1106366>", "<C-d>")

-- map shift + tab to indent left
vim.keymap.set("i", "<S-Tab>", "<C-d>")

-- escape from terminal mode with shift + escape
vim.keymap.set("t", "<S-Esc>", "<C-\\><C-n>")

-- Move visual/wrapped lines with j/k whilst preserving v.count expressions
vim.keymap.set({ "n", "x" }, "j", function()
	return vim.v.count > 0 and "j" or "gj"
end, { expr = true })
vim.keymap.set({ "n", "x" }, "k", function()
	return vim.v.count > 0 and "k" or "gk"
end, { expr = true })

-- Select older/newer quickfix lists
vim.keymap.set("n", "[f", function()
	vim.cmd("colder")
end)
vim.keymap.set("n", "]f", function()
	vim.cmd("cnewer")
end)
