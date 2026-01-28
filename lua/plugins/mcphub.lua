return {
	"mcphub-nvim",
	for_cat = "codecompanion",
	dep_of = { "codecompanion.nvim" },
	after = function()
		local async = require("plenary.async")
		local Path = require("plenary.path")
		local mcphub = require("mcphub")

		-- Constants and default configuration
		local CONFIG_FILES = {
			".mcphub/servers.json",
			".vscode/mcp.json",
			".cursor.mcp.json",
		}
		local PORT_RANGE_START = 1024
		local PORT_RANGE_END = 65535

		-- Hash the current working directory to generate a unique port
		local function hash_string(str)
			local hash = 5381
			for i = 1, #str do
				hash = ((hash * 33) + string.byte(str, i)) % (2 ^ 32)
			end
			return hash
		end

		local cwd = vim.fn.getcwd()
		local hashed_cwd = hash_string(cwd)
		local port = PORT_RANGE_START + (hashed_cwd % (PORT_RANGE_END - PORT_RANGE_START + 1))

		-- Helper: search cwd and ancestors for any of the CONFIG_FILES
		local function find_config_in_ancestors(files)
			local dir = vim.fn.getcwd()
			while true do
				local p = Path:new(dir)
				for _, f in ipairs(files) do
					if Path:new(dir, f):exists() then
						return Path:new(dir, f):absolute()
					end
				end
				local parent = p:parent().filename
				if parent == dir or parent == "" then
					break
				end
				dir = parent
			end
			return nil
		end

		-- Start async initialization
		async.run(function()
			-- Initialize the plugin immediately
			async.util.scheduler()

			-- Run async tasks in the background
			vim.schedule(function()
				vim.api.nvim_create_user_command("MCPStart", function()
					mcphub.setup({ port = port })
				end, { desc = "Start MCP Hub server" })

				-- Always define these commands regardless of auto-start
				vim.api.nvim_create_user_command("MCPRestart", function()
					mcphub.get_hub_instance():stop()
					mcphub.get_hub_instance():start()
				end, { desc = "Restart MCP Hub server" })

				vim.api.nvim_create_user_command("MCPStop", function()
					mcphub.get_hub_instance():stop()
					console_log.log("MCP Hub stopped", vim.log.levels.INFO)
				end, { desc = "Stop MCP Hub server" })

				-- keybind to open/start MCP Hub
				vim.keymap.set("n", "<leader>mh", function()
					local State = require("mcphub.state")
					if State.setup_state == "not_started" then
						require("mcphub").setup({
							port = port,
						})
					end
					if State.ui_instance then
						-- UI exists, just toggle it
						State.ui_instance:toggle()
					else
						State.ui_instance = require("mcphub.ui"):new()
						State.ui_instance:toggle()
					end
				end, { desc = "Open/Start MCP Hub", silent = true })

				-- Auto-start if any config file is present in cwd or ancestors
				local cfg_path = find_config_in_ancestors(CONFIG_FILES)
				if cfg_path then
					vim.notify("Found MCP config at " .. cfg_path .. " — auto-starting mcp-hub", vim.log.levels.INFO)
					mcphub.setup({ port = port })
				end
			end)
		end, function(err)
			if err then
				vim.schedule(function()
					vim.notify("Error in MCP Hub initialization: " .. tostring(err), vim.log.levels.ERROR)
				end)
			end
		end)
	end,
}
