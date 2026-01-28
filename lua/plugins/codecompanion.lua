-- Get the current buffer's path relative to project root
local function get_relative_path()
	-- Try to get the root directory using LSP workspace folders first
	local root = vim.lsp.buf.list_workspace_folders()[1]

	if not root then
		-- Fallback: try to find git root
		root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	end

	if not root then
		-- If no root found, return the full path
		return vim.fn.expand("%:p")
	end

	-- Get absolute path of current buffer
	local absolute_path = vim.fn.expand("%:p")
	-- Make it relative to the root
	return vim.fn.fnamemodify(absolute_path, ":~:." .. root .. "/")
end

return {
	{
		"codecompanion.nvim",
		for_cat = "codecompanion",
		after = function()
			local copilot_adapter = require("codecompanion.adapters").extend("copilot", {
				schema = {
					model = {
						default = "gpt-5-mini",
					},
				},
			})

			require("codecompanion").setup({
				adapters = {
					http = {
						copilot = function()
							return copilot_adapter
						end,
					},
				},
				interactions = {
					chat = {
						adapter = "copilot",
						slash_commands = {
							["buffer"] = {
								opts = {
									provider = "fzf_lua",
								},
							},
						},

						agents = {
							adapter = "copilot",
						},

						roles = {
							llm = function(adapter)
								return string.format(
									" %s%s",
									adapter.formatted_name,
									adapter.parameters
											and adapter.parameters.model
											and " (" .. adapter.parameters.model .. ")"
										or ""
								)
							end,
							user = " " .. "User",
						},
					},
					inline = {
						adapter = "copilot",
					},
				},
				extensions = {
					mcphub = {
						callback = "mcphub.extensions.codecompanion",
						opts = {
							make_vars = true,
							make_slash_commands = true,
							show_results_in_chat = true,
						},
					},
					-- vectorcode = {
					-- 	opts = {
					-- 		add_tool = true,
					-- 		add_slash_command = true,
					-- 		tool_opts = {},
					-- 	},
					-- },
					history = {
						enabled = true,
						opts = {
							-- Keymap to open history from chat buffer (default: gh)
							keymap = "gh",
							-- Keymap to save the current chat manually (when auto_save is disabled)
							save_chat_keymap = "sc",
							-- Save all chats by default (disable to save only manually using 'sc')
							auto_save = true,
							-- Number of days after which chats are automatically deleted (0 to disable)
							expiration_days = 0,
							-- Picker interface (auto resolved to a valid picker)
							picker = "fzf-lua", --- ("telescope", "snacks", "fzf-lua", or "default")
							---Optional filter function to control which chats are shown when browsing
							chat_filter = nil, -- function(chat_data) return boolean end
							-- Customize picker keymaps (optional)
							picker_keymaps = {
								rename = { n = "r", i = "<M-r>" },
								delete = { n = "d", i = "<M-d>" },
								duplicate = { n = "<C-y>", i = "<C-y>" },
							},
							---Automatically generate titles for new chats
							auto_generate_title = true,
							title_generation_opts = {
								---Adapter for generating titles (defaults to current chat adapter)
								adapter = nil, -- "copilot"
								---Model for generating titles (defaults to current chat model)
								model = nil, -- "gpt-4o"
								---Number of user prompts after which to refresh the title (0 to disable)
								refresh_every_n_prompts = 0, -- e.g., 3 to refresh after every 3rd user prompt
								---Maximum number of times to refresh the title (default: 3)
								max_refreshes = 3,
								format_title = function(original_title)
									-- this can be a custom function that applies some custom
									-- formatting to the title.
									return original_title
								end,
							},
							---On exiting and entering neovim, loads the last chat on opening chat
							continue_last_chat = false,
							---When chat is cleared with `gx` delete the chat from history
							delete_on_clearing_chat = false,
							---Directory path to save the chats
							dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
							---Enable detailed logging for history extension
							enable_logging = false,

							-- Summary system
							summary = {
								-- Keymap to generate summary for current chat (default: "gcs")
								create_summary_keymap = "gcs",
								-- Keymap to browse summaries (default: "gbs")
								browse_summaries_keymap = "gbs",

								generation_opts = {
									adapter = nil, -- defaults to current chat adapter
									model = nil, -- defaults to current chat model
									context_size = 90000, -- max tokens that the model supports
									include_references = true, -- include slash command content
									include_tool_outputs = true, -- include tool execution results
									system_prompt = nil, -- custom system prompt (string or function)
									format_summary = nil, -- custom function to format generated summary e.g to remove <think/> tags from summary
								},
							},

							-- Memory system (requires VectorCode CLI)
							memory = {
								-- Automatically index summaries when they are generated
								auto_create_memories_on_summary_generation = true,
								-- Path to the VectorCode executable
								vectorcode_exe = "vectorcode",
								-- Tool configuration
								tool_opts = {
									-- Default number of memories to retrieve
									default_num = 10,
								},
								-- Enable notifications for indexing progress
								notify = true,
								-- Index all existing memories on startup
								-- (requires VectorCode 0.6.12+ for efficient incremental indexing)
								index_on_startup = false,
							},
						},
					},
				},
			})

			vim.keymap.set({ "n", "x" }, "<leader>cc", function()
				vim.cmd("CodeCompanionChat Toggle")
			end, { noremap = true, silent = true, desc = "Toggle the CodeCompanion chat" })

			vim.keymap.set({ "n", "x" }, "<leader>cC", function()
				vim.cmd("CodeCompanionChat")
			end, { noremap = true, silent = true, desc = "Create a new CodeCompanion chat" })

			vim.keymap.set({ "n", "x" }, "<leader>ci", function()
				vim.cmd("CodeCompanion")
			end, { noremap = true, silent = true, desc = "Open the CodeCompanion inline chat" })

			vim.keymap.set({ "n", "x" }, "<leader>ca", function()
				vim.cmd("CodeCompanionActions")
			end, { noremap = true, silent = true, desc = "Open the CodeCompanion actions menu" })

			vim.keymap.set({ "n", "x" }, "<leader>cm", function()
				local models = copilot_adapter.schema.model.choices(copilot_adapter, {
					async = false,
				})
				local model_names = {}
				for name, _ in pairs(models) do
					table.insert(model_names, name)
				end

				local Chat = require("codecompanion").last_chat()

				if not Chat then
					return vim.notify("No chat found", vim.log.levels.ERROR)
				end

				vim.ui.select(model_names, {
					prompt = "Select model:",
				}, function(model)
					if model then
						Chat:apply_model_or_command({ model = model })
						vim.notify("Model changed to: " .. model)
					end
				end)
			end, { noremap = true, silent = true, desc = "Change the model" })

			vim.keymap.set({ "n", "x" }, "<leader>cb", function()
				local mode = vim.api.nvim_get_mode().mode
				if mode == "v" or mode == "V" or mode == "\22" then -- "\22" is the code for <CTRL-V>
					vim.cmd("CodeCompanionChat Add")
				else
					local Chat = require("codecompanion").last_chat()

					if not Chat then
						return vim.notify("No chat found", vim.log.levels.ERROR)
					end

					local path = get_relative_path()
					local file = vim.api.nvim_buf_get_name(0)

					local id = "<file>" .. path .. "</file>"

					Chat.references:add({
						id = id,
						path = path,
						source = "codecompanion.strategies.chat.slash_commands.file",
						opts = {
							pinned = true,
						},
					})

					vim.notify(string.format("File `%s` content added to the chat", file), vim.log.levels.INFO)
				end
			end, { noremap = true, silent = true, desc = "Add the current buffer to the chat" })
		end,
	},
	{
		"codecompanion-history.nvim",
		for_cat = "codecompanion",
		dep_of = { "codecompanion.nvim" },
	},
}
