return {
	"stevearc/conform.nvim",
	for_cat = "conform",
	after = function()
		local devenv = require("utils.dev-env")
		local file_exists = require("utils.file-exists")

		local prettier = (
			file_exists({
					"biome.json",
					"biome.toml",
				})
				and {
					"biome",
					"biome-organize-imports",
				}
			or devenv.create_libs_table({
				devenv.check_lib("dprint", function()
					return file_exists({
						"dprint.toml",
						"dprint.json",
					})
				end),
				devenv.check_lib("prettierd", function()
					return true
				end),
				devenv.check_lib("prettier", function()
					return true
				end),
			}, function(table)
				table.stop_after_first = true

				return table
			end)
		)

		return {
			-- Define your formatters
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = prettier,
				typescript = prettier,
				typescriptreact = prettier,
				javascriptreact = prettier,
				liquid = prettier,
				json = prettier,
				helm = prettier,
				yaml = prettier,
				nix = { "nixfmt", stop_after_first = true },
				blade = prettier,
				php = prettier,
				astro = prettier,
				mdx = prettier,
				css = prettier,
				scss = prettier,
				tex = { "tex-fmt" },
			},
			-- Set up format-on-save
			format_on_save = function(bufnr)
				-- Disable with a global or buffer-local variable
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end

				return { timeout_ms = 1000, lsp_format = "fallback" }
			end,
		}
	end,
	---@param opts ConformOpts
	config = function(_, opts)
		vim.api.nvim_create_user_command("FormatDisable", function(args)
			if args.bang then
				-- FormatDisable! will disable formatting just for this buffer
				vim.b.disable_autoformat = true
			else
				vim.g.disable_autoformat = true
			end
		end, {
			desc = "Disable autoformat-on-save",
			bang = true,
		})

		vim.api.nvim_create_user_command("FormatEnable", function()
			vim.b.disable_autoformat = false
			vim.g.disable_autoformat = false
		end, {
			desc = "Re-enable autoformat-on-save",
		})

		vim.api.nvim_create_user_command("SaveWithoutFormatting", function()
			vim.cmd("FormatDisable")
			vim.cmd("noa w")
			vim.cmd("FormatEnable")
		end, {
			desc = "Save without formatting",
		})

		vim.api.nvim_create_user_command("Format", function(args)
			local range = nil
			if args.count ~= -1 then
				local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
				range = {
					start = { args.line1, 0 },
					["end"] = { args.line2, end_line:len() },
				}
			end
			require("conform").format({ async = true, lsp_format = "fallback", range = range })
		end, { range = true })

		require("conform").setup(opts)
	end,
}
