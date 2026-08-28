return {
	"render-markdown.nvim",
	for_cat = "markdown",
	after = function()
		-- Map: source_bufnr -> { win = winid, buf = bufnr }
		local rendered_by_source = {}

		local function is_valid_win(win)
			return win and vim.api.nvim_win_is_valid(win)
		end

		local function is_valid_buf(buf)
			return buf and vim.api.nvim_buf_is_valid(buf)
		end

		local function cleanup_entry(source_buf)
			local entry = rendered_by_source[source_buf]
			if not entry then
				return
			end
			if not is_valid_win(entry.win) then
				entry.win = nil
			end
			if not is_valid_buf(entry.buf) then
				entry.buf = nil
			end
			if not entry.win and not entry.buf then
				rendered_by_source[source_buf] = nil
			end
		end

		local function close_rendered_for(source_buf)
			cleanup_entry(source_buf)
			local entry = rendered_by_source[source_buf]
			if not entry then
				return
			end

			-- Prefer closing the window if it exists
			if is_valid_win(entry.win) then
				-- pcall in case it's the last window, etc.
				pcall(vim.api.nvim_win_close, entry.win, true)
			end

			-- If buffer still exists, wipe it
			if is_valid_buf(entry.buf) then
				pcall(vim.api.nvim_buf_delete, entry.buf, { force = true })
			end

			rendered_by_source[source_buf] = nil
		end

		-- Store mapping of source to destination buffers
		local synced_buffers = {}
		local function create_synced_preview(src_buf)
			-- Toggle: close if already exists
			if synced_buffers[src_buf] then
				vim.api.nvim_buf_delete(synced_buffers[src_buf], {})
				synced_buffers[src_buf] = nil
				return
			end

			local src_win = vim.fn.bufwinid(src_buf)
			local dst_buf = vim.api.nvim_create_buf(false, true)
			local dst_win = vim.api.nvim_open_win(dst_buf, false, {
				split = "right",
			})
			synced_buffers[src_buf] = dst_buf

			-- Configure destination buffer
			vim.bo[dst_buf].bufhidden = "wipe"
			vim.bo[dst_buf].buftype = "nofile"
			vim.bo[dst_buf].filetype = vim.bo[src_buf].filetype
			vim.bo[dst_buf].modifiable = false
			vim.bo[dst_buf].swapfile = false

			-- Function to sync lines using vim.diff for efficiency
			local function sync_lines()
				local src_lines = vim.api.nvim_buf_get_lines(src_buf, 0, -1, false)
				local dst_lines = vim.api.nvim_buf_get_lines(dst_buf, 0, -1, false)

				local src_text = table.concat(src_lines, "\n") .. "\n"
				local dst_text = table.concat(dst_lines, "\n") .. "\n"
				local diff = vim.diff(dst_text, src_text, { result_type = "indices" })

				if type(diff) == "table" then
					vim.bo[dst_buf].modifiable = true
					-- Apply hunks in reverse order to maintain line numbers
					for i = #diff, 1, -1 do
						local start_a, count_a, start_b, count_b = unpack(diff[i])
						local line_start = start_a - 1
						local line_end = start_a + count_a - 1
						if count_a == 0 then
							line_start = line_start + 1
							line_end = line_end + 1
						end
						vim.api.nvim_buf_set_lines(
							dst_buf,
							line_start,
							line_end,
							false,
							vim.list_slice(src_lines, start_b, start_b + count_b - 1)
						)
					end
					vim.bo[dst_buf].modifiable = false
				end
			end

			-- Function to sync cursor position
			local function sync_cursor()
				if vim.api.nvim_win_is_valid(src_win) and vim.api.nvim_win_is_valid(dst_win) then
					local cursor = vim.api.nvim_win_get_cursor(src_win)
					pcall(vim.api.nvim_win_set_cursor, dst_win, cursor)
				end
			end

			-- Initial sync
			sync_lines()
			sync_cursor()

			local group = vim.api.nvim_create_augroup("BufferSync_" .. src_buf, { clear = true })

			-- Sync on content changes
			vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
				group = group,
				buffer = src_buf,
				callback = function()
					sync_lines()
					sync_cursor()
				end,
			})

			-- Sync on cursor movement
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				group = group,
				buffer = src_buf,
				callback = sync_cursor,
			})

			-- Cleanup when destination buffer is closed
			vim.api.nvim_create_autocmd("BufWipeout", {
				group = group,
				buffer = dst_buf,
				once = true,
				callback = function()
					synced_buffers[src_buf] = nil
					vim.api.nvim_clear_autocmds({ group = group })
				end,
			})

			return {
				buf = dst_buf,
				win = dst_win,
			}
		end

		require("render-markdown").setup({
			enabled = false,
			file_types = { "markdown", "codecompanion" },
			patterns = { markdown = { disable = false } },
			overrides = { buftype = { nofile = { enabled = false } } },
			win_options = { conceallevel = { rendered = 1 } },

			on = {
				attach = function(ctx)
					local bufnr = ctx.buf

					-- Toggle rendered markdown with <leader>md
					vim.keymap.set("n", "<leader>md", function()
						require("render-markdown").buf_toggle()
					end, {
						desc = "Toggle rendered markdown",
						buffer = bufnr,
						noremap = true,
						silent = true,
					})

					-- Open rendered markdown in a split with <leader>mD
					vim.keymap.set("n", "<leader>mD", function()
						cleanup_entry(bufnr)
						local entry = rendered_by_source[bufnr]

						-- If we already have a valid rendered window, close it (toggle behavior)
						if entry and is_valid_win(entry.win) then
							close_rendered_for(bufnr)
							return
						end

						local orig_win = vim.api.nvim_get_current_win()

						-- Create split
						local preview = create_synced_preview(bufnr)

						-- If preview creation failed, abort
						if not preview or not vim.api.nvim_win_is_valid(preview.win) then
							return
						end

						local new_win = preview.win

						-- Focus new split and toggle render
						vim.api.nvim_set_current_win(new_win)
						require("render-markdown").buf_toggle()

						-- Record what buffer ended up in the rendered window
						rendered_by_source[bufnr] = {
							win = new_win,
							buf = vim.api.nvim_win_get_buf(new_win),
						}

						-- Return focus
						if vim.api.nvim_win_is_valid(orig_win) then
							vim.api.nvim_set_current_win(orig_win)
						end
					end, {
						desc = "Open rendered markdown in split",
						buffer = bufnr,
						noremap = true,
						silent = true,
					})
				end,
			},

			sign = {
				enabled = false,
			},
		})

		-- When filetype is codecompanion, enable render-markdown
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "codecompanion",
			callback = function()
				require("render-markdown").buf_enable()
			end,
		})
	end,
}
