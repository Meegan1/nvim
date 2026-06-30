return {
	{
		"nvim-web-devicons",
		for_cat = "incline",
	},
	{

		"incline.nvim",
		for_cat = "incline",
		after = function()
			require("lze").trigger_load("nvim-web-devicons")

			local helpers = require("incline.helpers")
			local devicons = require("nvim-web-devicons")

			-- Constants
			local WINDOW_CONFIG = {
				padding = 0,
				margin = { horizontal = 0 },
				overlap = { winbar = true },
			}

			local BACKGROUND_COLOR = "#44406e"
			local NO_NAME_PLACEHOLDER = "[No Name]"

			-- Get formatted filename for the buffer
			local function get_formatted_filename(buf_id)
				local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf_id), ":t")
				return filename ~= "" and filename or NO_NAME_PLACEHOLDER
			end

			-- Get file icon and styling
			local function get_file_icon_component(filename)
				local icon, color = devicons.get_icon_color(filename)
				if not icon then
					return ""
				end

				return {
					" ",
					icon,
					" ",
					guibg = color,
					guifg = helpers.contrast_color(color),
				}
			end

			-- Get filename component with modification indicator
			local function get_filename_component(filename, is_modified)
				return {
					filename,
					gui = is_modified and "bold,italic" or "bold",
					group = is_modified and "BufferCurrentMod" or nil,
				}
			end

			-- Main render function
			local function render(props)
				local filename = get_formatted_filename(props.buf)
				local is_modified = vim.bo[props.buf].modified

				return {
					get_file_icon_component(filename),
					" ",
					get_filename_component(filename, is_modified),
					is_modified and { " ●", group = "BufferCurrentMod" } or " ",
					" ",
					guibg = BACKGROUND_COLOR,
				}
			end

			require("incline").setup({
				window = WINDOW_CONFIG,
				render = render,
			})
		end,
	},
}
