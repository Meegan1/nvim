local curl = require("plenary.curl")

local M = {
	schemas_catalog = "datreeio/CRDs-catalog",
	schema_catalog_branch = "main",
	github_base_api_url = "https://api.github.com/repos",
	github_headers = {
		Accept = "application/vnd.github+json",
		["X-GitHub-Api-Version"] = "2022-11-28",
	},
}
M.schema_url = "https://raw.githubusercontent.com/" .. M.schemas_catalog .. "/" .. M.schema_catalog_branch

M.list_github_tree = function()
	local url = M.github_base_api_url .. "/" .. M.schemas_catalog .. "/git/trees/" .. M.schema_catalog_branch
	local response = curl.get(url, { headers = M.github_headers, query = { recursive = 1 } })
	local body = vim.fn.json_decode(response.body)
	local trees = {}
	for _, tree in ipairs(body.tree) do
		if tree.type == "blob" and tree.path:match("%.json$") then
			table.insert(trees, tree.path)
		end
	end
	return trees
end

M.find_nearest_schema = function()
	-- Get the current cursor position
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_line = cursor_pos[1] - 1

	-- Initialize variables to store apiVersion and kind
	local api_version, kind

	-- Function to search for apiVersion and kind in a given range
	local function search_range(start_line, end_line, step)
		for i = start_line, end_line, step do
			local line = vim.api.nvim_buf_get_lines(0, i, i + 1, false)[1]
			if line:match("^---") then
				break
			elseif line:match("^apiVersion:") then
				api_version = line:match("^apiVersion:%s*(.*)")
			elseif line:match("^kind:") then
				kind = line:match("^kind:%s*(.*)")
			end
			if api_version and kind then
				break
			end
		end
	end

	-- Search upwards from the cursor position
	search_range(cursor_line, 0, -1)

	-- If not found, search downwards from the cursor position
	if not (api_version and kind) then
		search_range(cursor_line, vim.api.nvim_buf_line_count(0) - 1, 1)
	end

	-- Set the default search based on apiVersion and kind
	local schema = ""
	if api_version and kind then
		local base_url = api_version:match("^(.-)/v%d+")
		local version = api_version:match(".*/(v%d+)")
		schema = base_url .. "/" .. kind:lower() .. "_" .. version .. ".json"
	end

	return schema
end

M.set_schema = function(schema)
	local schema_url = M.schema_url .. "/" .. schema
	local schema_modeline = "# yaml-language-server: $schema=" .. schema_url

	-- Find the nearest `---` line above the cursor
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1] - 1
	local found_modeline = false
	local found_delimiter = false

	for i = line_num, 0, -1 do
		local line = vim.api.nvim_buf_get_lines(0, i, i + 1, false)[1]
		if line:match("^# yaml%-language%-server: %$schema=") then
			vim.api.nvim_buf_set_lines(0, i, i + 1, false, { schema_modeline })
			found_modeline = true
			break
		elseif line == "---" then
			vim.api.nvim_buf_set_lines(0, i + 1, i + 1, false, { schema_modeline })
			found_delimiter = true
			break
		end
	end

	-- If no modeline or `---` line is found, insert at the top
	if not found_modeline and not found_delimiter then
		vim.api.nvim_buf_set_lines(0, 0, 0, false, { schema_modeline })
	end

	vim.notify("Added schema modeline: " .. schema_modeline)
end

M.auto_init = function()
	local schema = M.find_nearest_schema()
	print(schema)
	if schema == "" then
		vim.notify("No schema found.")
		return
	end

	local results = M.list_github_tree()
	for _, result in ipairs(results) do
		if result:match(schema) then
			M.set_schema(result)
			break
		end
	end
end

M.init = function()
	local results = M.list_github_tree()

	if #results == 0 then
		return
	end

	require("snacks").picker.select(results, {
		prompt = "Select schema> ",
	}, function(selected)
		if not selected then
			vim.notify("No schema selected")
			return
		end
		M.set_schema(selected)
	end)
end

M.setup = function()
	vim.api.nvim_create_user_command("YamlSchemaInit", function()
		M.init()
	end, {
		desc = "Initialize YAML schema",
	})

	vim.api.nvim_create_user_command("YamlSchemaAutoInit", function()
		M.auto_init()
	end, {
		desc = "Auto initialize YAML schema",
	})
end

return M
