local CodeSnap = {}

local function get_visual_selection()
	local bufnr = vim.api.nvim_get_current_buf()
	local start_pos = vim.fn.getpos("v")
	local end_pos = vim.fn.getpos(".")
	local start_row = start_pos[2]
	local end_row = end_pos[2]

	-- Ensure start is before end
	if start_row > end_row then
		start_row, end_row = end_row, start_row
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, false)
	if #lines == 0 then
		return nil
	end
	return table.concat(lines, "\n")
end

local function get_buffer_content()
	return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

local option_arg_map = {
	theme = {
		type = "string",
		description = "Theme to use for the snapshot",
		arg = "--theme",
	},
	config = {
		type = "string",
		description = "Path to the configuration file",
		arg = "--config",
	},
	scale = {
		type = "number",
		description = "Scale factor for the snapshot",
		arg = "--scale",
	},
	output = {
		type = "string",
		description = "Output file path for the snapshot",
		arg = "-o",
	},
	clipboard = {
		type = "boolean",
		description = "Copy the snapshot to the clipboard",
		option = "output",
		value = "clipboard",
	},
	watermark = {
		type = "boolean",
		description = "Add a watermark to the snapshot",
		arg = "--watermark",
		value = "watermark",
	},
	-- add more mappings as needed
}

local function remove_arg(cmd, arg)
	local i = 1
	while i <= #cmd do
		if cmd[i] == arg then
			table.remove(cmd, i) -- remove arg
			-- Remove value if present and not another flag
			if cmd[i] and not tostring(cmd[i]):match("^%-") then
				table.remove(cmd, i)
			end
		else
			i = i + 1
		end
	end
end

local function get_option_value(cmd, option)
	for i = 1, #cmd do
		if cmd[i] == option then
			if i + 1 <= #cmd and not cmd[i + 1]:match("^%-") then
				return cmd[i + 1]
			end
			return true -- Option is present but no value provided
		end
	end
	return nil -- Option not found
end

function CodeSnap.snapshot(opts)
	opts = opts or {}
	local tmpfile = vim.fn.tempname() .. ".txt"
	local outfile = opts.output or (vim.fn.getcwd() .. "/codesnap.png")
	local content

	if opts.visual then
		content = get_visual_selection()
	else
		content = get_buffer_content()
	end

	if not content or content == "" then
		vim.notify("No content to snapshot", vim.log.levels.WARN)
		return
	end

	local f = io.open(tmpfile, "w")
	f:write(content)
	f:close()

	local cmd = {
		"codesnap",
		"-f",
		tmpfile,
		"-o",
		outfile,
		"--margin-x",
		"0",
		"--margin-y",
		"0",
		"--mac-window-bar",
		"false",
		"--watermark",
		'""',
    "--code-font-family",
    '"Monaspace Neon"',
		"--language",
		vim.bo.filetype,
	}

	-- First pass: handle "option" overrides
	for k, v in pairs(opts) do
		local mapping = option_arg_map[k]
		if mapping and mapping.option and v then
			opts[mapping.option] = mapping.value
		end
	end

	-- Second pass: handle "arg" options, removing duplicates
	for k, v in pairs(opts) do
		local mapping = option_arg_map[k]
		if mapping and mapping.arg and k ~= "visual" then
			remove_arg(cmd, mapping.arg)
			if v ~= nil and v ~= false then
				table.insert(cmd, mapping.arg)
				if mapping.type ~= "boolean" then
					table.insert(cmd, tostring(v))
				end
			end
		end
	end

	local cmd_str = table.concat(cmd, " ")

	vim.notify("Running CodeSnap with command: " .. cmd_str, vim.log.levels.INFO)

	vim.fn.jobstart(cmd_str, {
		on_exit = function(_, code)
			os.remove(tmpfile)

			local output_option = get_option_value(cmd, "-o")
			if code == 0 then
				vim.notify("CodeSnap saved to " .. output_option, vim.log.levels.INFO)
			else
				vim.notify("CodeSnap failed", vim.log.levels.ERROR)
			end
		end,
	})
end

vim.api.nvim_create_user_command("CodeSnap", function(opts)
	CodeSnap.snapshot({ visual = opts.range > 0, clipboard = true })
end, { range = true })

return CodeSnap
