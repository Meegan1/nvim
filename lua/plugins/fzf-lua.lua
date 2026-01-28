return {
	"fzf-lua",
	for_cat = "fzf-lua",
	after = function()
		local fzf = require("fzf-lua")

		fzf.setup({
			keymap = {
				-- Customize key mappings in fzf window
				build_in = {
					["<C-.>"] = "accept",
					["l"] = "accept",
				},
			},
			-- winopts = {
			-- 	-- Window layout options
			-- 	-- height = 0.85,
			-- 	-- width = 0.80,
			-- 	-- preview = {
			-- 	-- 	hidden = "hidden",
			-- 	-- },
			-- },

			lsp = {
				symbols = {
					symbol_hl = function(s)
						return "TroubleIcon" .. s
					end,
					symbol_fmt = function(s)
						return s:lower() .. "\t"
					end,
					child_prefix = false,
				},
			},
		})
		fzf.register_ui_select(function(fzf_opts, items)
			local opts = vim.tbl_deep_extend("force", fzf_opts, {
				prompt = " ",
				winopts = {
					title = " " .. vim.trim((fzf_opts.prompt or "Select"):gsub("%s*:%s*$", "")) .. " ",
					title_pos = "center",
				},
			}, fzf_opts.kind == "codeaction" and {
				winopts = {
					layout = "vertical",
					-- height is number of items minus 15 lines for the preview, with a max of 80% screen height
					height = math.floor(math.min(vim.o.lines * 0.8 - 16, #items + 2) + 0.5) + 16,
					width = 0.5,
					preview = {
						layout = "vertical",
						vertical = "up:15,border-top",
					},
				},
			} or {
				winopts = {
					width = 0.5,
					-- height is number of items, with a max of 80% screen height
					height = math.floor(math.min(vim.o.lines * 0.8, #items + 2) + 0.5),
				},
			})

			return opts
		end)

		local config = fzf.config

		-- Quickfix
		config.defaults.keymap.fzf["ctrl-q"] = "select-all+accept"
		config.defaults.keymap.fzf["ctrl-u"] = "half-page-up"
		config.defaults.keymap.fzf["ctrl-d"] = "half-page-down"
		config.defaults.keymap.fzf["ctrl-x"] = "jump"
		config.defaults.keymap.fzf["ctrl-f"] = "preview-page-down"
		config.defaults.keymap.fzf["ctrl-b"] = "preview-page-up"
		config.defaults.keymap.builtin["<c-f>"] = "preview-page-down"
		config.defaults.keymap.builtin["<c-b>"] = "preview-page-up"

		local find_files = function()
			return fzf.files({
				hidden = true,
				fd_opts = "--type f --hidden --exclude .git",
			})
		end

		local find_live_grep = function()
			return fzf.live_grep({
				hidden = true,
				no_ignore = true,
				rg_opts = "--column --line-number -g '!**/{.git,dist,vendor,node_modules,coverage,.next,.nx,storage/runtime,storage/logs,storage/backups,storage/composer-backups,.devenv,.direnv,.moon/cache}/**'",
			})
		end

		-- Files with hidden files and ignore .git
		vim.keymap.set({ "n", "i", "v" }, "<C-p>", function()
			find_files()
		end, {
			desc = "fzf-lua: files",
		})
		vim.keymap.set({ "n" }, "<leader>fd", function()
			find_files()
		end, {
			desc = "fzf-lua: files",
		})

		-- Commands
		vim.keymap.set({ "n", "i", "v" }, "<C-S-P>", function()
			fzf.commands()
		end, {
			desc = "fzf-lua: commands",
		})
		vim.keymap.set({ "n" }, "<leader>fc", function()
			fzf.commands()
		end, {
			desc = "fzf-lua: commands",
		})

		-- Buffers
		vim.keymap.set({ "n" }, "<leader>fb", function()
			fzf.buffers()
		end, {
			desc = "fzf-lua: buffers",
		})

		-- Blines
		-- Search in current file
		vim.keymap.set("n", "<C-f>", function()
			fzf.blines()
		end, {
			desc = "fzf-lua: blines",
		})
		vim.keymap.set("n", "<leader>fi", function()
			fzf.blines()
		end, {
			desc = "fzf-lua: blines",
		})

		-- Live grep with hidden files
		vim.keymap.set("n", "<C-S-F>", function()
			find_live_grep()
		end, {
			desc = "fzf-lua: live grep",
		})
		vim.keymap.set("n", "<leader>fg", function()
			find_live_grep()
		end, {
			desc = "fzf-lua: live grep",
		})

		-- LSP workspace symbols
		vim.keymap.set("n", "<C-t>", function()
			fzf.lsp_workspace_symbols()
		end, {
			desc = "fzf-lua: lsp workspace symbols",
		})
		vim.keymap.set("n", "<leader>fs", function()
			fzf.lsp_workspace_symbols()
		end, {
			desc = "fzf-lua: lsp workspace symbols",
		})

		-- Undo history (built into fzf-lua)
		vim.keymap.set("n", "<leader>fu", function()
			require("modules.fzf.undo").undo()
		end, {
			desc = "fzf-lua: undo history",
		})

		-- FZF-Lua LSP code actions
		vim.keymap.set({ "n", "i", "v" }, "<C-.>", function()
			fzf.lsp_code_actions()
		end, {
			desc = "fzf-lua: lsp code actions",
		})

		-- Add keybinding for snippets
		vim.keymap.set("n", "<leader>fs", function()
			require("modules.fzf.snippets").find_snippets()
		end, {
			desc = "fzf-lua: luasnip snippets",
		})

		-- LSP Diagnostics
		vim.keymap.set("n", "<leader>fp", function()
			fzf.lsp_workspace_diagnostics()
		end, {
			desc = "fzf-lua: lsp diagnostics",
		})
	end,
}
