local ESC = vim.api.nvim_replace_termcodes("<esc>", true, true, true)

local on_attach = function(client, bufnr)
	-- Your on_attach function should set buffer-local lsp related settings
	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end
		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
	nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

	nmap("gh", vim.lsp.buf.hover, "Show LSP Info")
	nmap("gd", vim.lsp.buf.definition, "Open LSP Definition")
	nmap("gi", vim.lsp.buf.implementation, "Open LSP Implementation")
	nmap("gr", vim.lsp.buf.references, "Show LSP References")
	nmap("go", vim.lsp.buf.type_definition, "Open Type Definition")
	nmap("gs", vim.lsp.buf.signature_help, "Open Signature Help")

	-- bind <Esc> to close hover windows globally
	vim.on_key(function(key)
		if key == ESC and (vim.fn.mode() == "n" or vim.fn.mode() == "v") then
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local config = vim.api.nvim_win_get_config(win)
				if config.relative ~= "" then
					vim.api.nvim_win_close(win, false)
				end
			end
		end
	end)
	-- etc...
end

local lspConfig = function(plugin)
	vim.lsp.config(plugin.name, type(plugin.lsp) == "function" and plugin.lsp() or plugin.lsp or {})
end

local lspEnable = function(pluginName)
	require("lze").trigger_load("nvim-lspconfig")
	vim.lsp.enable(pluginName)
end

return {
	{
		"nvim-lspconfig",
		for_cat = "lsp",
		priority = 50,
		before = function()
			vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Open LSP diagnostic float" })
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Goto previous LSP Diagnostic" })
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Goto next LSP Diagnostic" })

			vim.lsp.config("*", {
				-- capabilities = capabilities,
				on_attach = on_attach,
			})
		end,
	},
	{
		"lazydev.nvim",
		for_cat = "lsp",
		ft = "lua",
		before = function(plugin)
			lspConfig(plugin)
		end,
		dep_of = "lua_ls",
		after = function()
			require("lazydev").setup({
				library = {
					{
						path = nixCats.nixCatsPath and nixCats.nixCatsPath .. "/lua" or nil,
						words = { "nixCats" },
					},
				},
			})
		end,
	},
	{
		"lua_ls",
		for_cat = "lsp",
		ft = "lua",
		before = function(plugin)
			lspConfig(plugin)
		end,
		load = function(name)
			lspEnable(name)
		end,
		lsp = {
			-- if you include a filetype, it doesnt call lspconfig for the list of filetypes (faster)
			filetypes = { "lua" },
			settings = {
				Lua = {
					runtime = { version = "LuaJIT" },
					formatters = {
						ignoreComments = true,
					},
					signatureHelp = { enabled = true },
					diagnostics = {
						globals = { "nixCats", "vim" },
						disable = { "missing-fields" },
					},
					workspace = {
						checkThirdParty = false,
						library = {
							-- '${3rd}/luv/library',
							-- unpack(vim.api.nvim_get_runtime_file('', true)),
						},
					},
					completion = {
						callSnippet = "Replace",
					},
					telemetry = { enabled = false },
				},
			},
		},
	},
	{
		"ts_ls",
		for_cat = "lsp",
		before = function(plugin)
			lspConfig(plugin)
		end,
		load = function(name)
			lspEnable(name)
		end,
		lsp = {
			init_options = { hostInfo = "neovim" },
			cmd = { "typescript-language-server", "--stdio" },
			filetypes = {
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
			},
			root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
			handlers = {
				-- handle rename request for certain code actions like extracting functions / types
				["_typescript.rename"] = function(_, result, ctx)
					local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
					vim.lsp.util.show_document({
						uri = result.textDocument.uri,
						range = {
							start = result.position,
							["end"] = result.position,
						},
					}, client.offset_encoding)
					vim.lsp.buf.rename()
					return vim.NIL
				end,
			},
			commands = {
				["editor.action.showReferences"] = function(command, ctx)
					local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
					local file_uri, position, references = unpack(command.arguments)

					local quickfix_items = vim.lsp.util.locations_to_items(references, client.offset_encoding)
					vim.fn.setqflist({}, " ", {
						title = command.title,
						items = quickfix_items,
						context = {
							command = command,
							bufnr = ctx.bufnr,
						},
					})

					vim.lsp.util.show_document({
						uri = file_uri,
						range = {
							start = position,
							["end"] = position,
						},
					}, client.offset_encoding)

					vim.cmd("botright copen")
				end,
			},
			on_attach = function(client, bufnr)
				on_attach(client, bufnr)

				-- Enable inlay hints if nvim version is 0.10 or higher
				if vim.fn.has("nvim-0.10") == 1 then
					vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
				end

				-- ts_ls provides `source.*` code actions that apply to the whole file. These only appear in
				-- `vim.lsp.buf.code_action()` if specified in `context.only`.
				vim.api.nvim_buf_create_user_command(bufnr, "LspTypescriptSourceAction", function()
					local source_actions = vim.tbl_filter(function(action)
						return vim.startswith(action, "source.")
					end, client.server_capabilities.codeActionProvider.codeActionKinds)

					vim.lsp.buf.code_action({
						context = {
							diagnostics = {},
							only = source_actions,
						},
					})
				end, {})

				vim.keymap.set("n", "<leader>ir", function()
					vim.lsp.buf.code_action({
						context = {
							diagnostics = {},
							---@diagnostic disable-next-line: assign-type-mismatch
							only = { "source.removeUnused.ts" },
						},
						apply = true,
					})
				end, {
					desc = "Remove unused imports",
					buffer = bufnr,
				})

				vim.keymap.set("n", "<leader>if", function()
					vim.lsp.buf.code_action({
						context = {
							diagnostics = {},
							---@diagnostic disable-next-line: assign-type-mismatch
							only = { "source.addMissingImports.ts" },
						},
						apply = true,
					})
				end, {
					desc = "Fix imports",
					buffer = bufnr,
				})
			end,
		},
	},
	{
		"yamlls",
		for_cat = "lsp",
		before = function(plugin)
			lspConfig(plugin)
		end,
		load = function(name)
			lspEnable(name)
		end,
		lsp = {
			settings = {
				yaml = {
					schemas = {
						kubernetes = "templates/**",
						["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
						["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
						["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
						["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
						["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
					},
				},
			},
			root_markers = { ".git", "package.json", "kustomization.yaml", "Chart.yaml" },
		},
	},
	{
		"jsonls",
		for_cat = "lsp",
		before = function(plugin)
			lspConfig(plugin)
		end,
		load = function(name)
			lspEnable(name)
		end,
		lsp = function()
			require("lze").trigger_load("SchemaStore.nvim")

			return {
				settings = {
					json = {
						schemas = require("schemastore").json.schemas(),
						validate = { enable = true },
					},
				},
				root_markers = { ".git", "package.json" },
				filetypes = {
					"json",
					"jsonc",
				},
				command = "vscode-json-language-server",
			}
		end,
	},
	{
		"nixd",
		for_cat = "lsp",
		before = function(plugin)
			lspConfig(plugin)
		end,
		load = function(name)
			lspEnable(name)
		end,
		lsp = function()
			local function get_nixd_settings()
				local sysname = vim.loop.os_uname().sysname
				local username = os.getenv("USER")

				local home_manager_expr
				if sysname == "Darwin" then
					local hostname = "macbook"
					home_manager_expr = string.format(
						"(builtins.getFlake (builtins.toString ./.)).darwinConfigurations.%s.options.home-manager.users.type.getSubOptions []",
						hostname
					)
				elseif sysname == "Linux" then
					local hostname = "nixos"
					home_manager_expr = string.format(
						"(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.%s.options.home-manager.users.%s.type.getSubOptions []",
						hostname,
						username
					)
				end

				local options = {
					home_manager = { expr = home_manager_expr },
				}
				if sysname == "Linux" then
					options.nixos = {
						expr = '(builtins.getFlake ("git+file://" + toString ./.)).nixosConfigurations.nixos.options',
					}
				end

				return {
					nixpkgs = { expr = "import <nixpkgs> { }" },
					formatting = { command = { "nixfmt" } },
					options = options,
				}
			end

			return {
				cmd = { "nixd" },
				settings = {
					nixd = get_nixd_settings(),
				},
				root_markers = { ".git", "flake.nix", "nixpkgs.json", "shell.nix", "default.nix" },
			}
		end,
	},
	{
		"biome",
		for_cat = "lsp",
		before = function(plugin)
			lspConfig(plugin)
		end,
		load = function(name)
			lspEnable(name)
		end,
		lsp = function()
			return {
				cmd = function(dispatchers, config)
					local cmd = "biome"
					local local_cmd = (config or {}).root_dir and config.root_dir .. "/node_modules/.bin/biome"
					if local_cmd and vim.fn.executable(local_cmd) == 1 then
						cmd = local_cmd
					end
					return vim.lsp.rpc.start({ cmd, "lsp-proxy" }, dispatchers)
				end,
				filetypes = {
					"astro",
					"css",
					"graphql",
					"html",
					"javascript",
					"javascriptreact",
					"json",
					"jsonc",
					"svelte",
					"typescript",
					"typescriptreact",
					"vue",
				},
				workspace_required = true,
				root_markers = { "biome.json", "biome.jsonc", "package.json", ".git" },
			}
		end,
	},
	{
		"astro",
		for_cat = "lsp",
		before = function(plugin)
			lspConfig(plugin)
		end,
		load = function(name)
			lspEnable(name)
		end,
		lsp = {
			filetypes = { "astro" },
			root_markers = { "package.json", ".git" },
			capabilities = {
				workspace = {
					didChangeWatchedFiles = {
						dynamicRegistration = true,
					},
				},
			},
		},
	},
	{
		"tailwindcss",
		for_cat = "lsp",
		before = function(plugin)
			lspConfig(plugin)
		end,
		load = function(name)
			lspEnable(name)
		end,
		lsp = {
			filetypes = {
				"html",
				"css",
				"scss",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"astro",
				"blade",
			},
			root_markers = {
				"tailwind.config.js",
				"tailwind.config.cjs",
				"tailwind.config.mjs",
				"package.json",
				".git",
			},
			settings = {
				tailwindCSS = {
					classFunctions = { "tw", "clsx", "classnames", "cn", "twMerge" },
				},
			},
		},
	},
	{
		"shopify_theme_ls",
		for_cat = "lsp",
		before = function(plugin)
			lspConfig(plugin)
		end,
		load = function(name)
			lspEnable(name)
		end,
	},
	{
		"intelephense",
		for_cat = "lsp",
		before = function(plugin)
			lspConfig(plugin)
		end,
		load = function(name)
			lspEnable(name)
		end,
		lsp = function()
			return {
				filetypes = {
					"php",
					"blade",
					"twig",
				},
			}
		end,
	},
	{
		"laravel_ls",
		for_cat = "lsp",
		before = function(plugin)
			lspConfig(plugin)
		end,
		load = function(name)
			lspEnable(name)
		end,
	},
	{
		"tombi",
		for_cat = "lsp",
		before = function(plugin)
			lspConfig(plugin)
		end,
		load = function(name)
			lspEnable(name)
		end,
	},
}
