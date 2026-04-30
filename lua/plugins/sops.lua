return {
	"sops",
	lazy = false,
	for_cat = "sops",
	load = function() end,
	after = function()
		local function sops_file_info()
			local f = vim.fn.expand("%:p")
			local d = vim.fn.expand("%:p:h")
			local ext = f:match("%.([^.]+)$")
			local type_flag = ({ yaml = "yaml", yml = "yaml", json = "json", env = "dotenv", ini = "ini" })[ext]
				or "yaml"
			return f, d, type_flag
		end

		local function direnv_exports(dir)
			return vim.fn.system(string.format("cd %s && direnv export bash 2>/dev/null", vim.fn.shellescape(dir)))
		end

		local function sops_run(dir, env, args, input)
			local cmd = string.format("cd %s && %s sops %s", vim.fn.shellescape(dir), env, args)
			local out = vim.fn.system(cmd, input)
			if vim.v.shell_error ~= 0 then
				return nil, out
			end
			return out, nil
		end

		local function buf_set_lines(lines_str)
			local lines = vim.split(lines_str, "\n", { plain = true })
			if lines[#lines] == "" then
				table.remove(lines)
			end
			vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
		end

		vim.api.nvim_create_user_command("Sops", function(opts)
			local subcmd = opts.fargs[1]

			if subcmd == "edit" then
				local f, d, type_flag = sops_file_info()

				vim.cmd("new")
				vim.cmd('execute "r !direnv exec ' .. d .. " sops -d " .. f .. ' 2>/dev/null"')
				vim.cmd("1d")

				local buf = vim.api.nvim_get_current_buf()
				vim.api.nvim_buf_set_name(buf, "sops://" .. f)
				vim.bo.buftype = "acwrite"
				vim.bo.swapfile = false
				vim.bo.undofile = false
				vim.bo.filetype = vim.filetype.match({ filename = f }) or "yaml"
				vim.bo.bufhidden = "delete"
				vim.bo.modified = false

				vim.api.nvim_create_autocmd("BufWriteCmd", {
					buffer = buf,
					callback = function()
						local plaintext = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
						local args = string.format(
							"--encrypt --input-type %s --output-type %s --filename-override %s /dev/stdin",
							type_flag,
							type_flag,
							vim.fn.shellescape(f)
						)
						local encrypted, err = sops_run(d, "", args, plaintext)
						if err then
							vim.notify("SOPS encryption failed:\n" .. err, vim.log.levels.ERROR)
							return
						end

						local fh = io.open(f, "w")
						if not fh then
							vim.notify("Could not open " .. f .. " for writing", vim.log.levels.ERROR)
							return
						end
						fh:write(encrypted)
						fh:close()

						for _, b in ipairs(vim.api.nvim_list_bufs()) do
							if vim.api.nvim_buf_get_name(b) == f then
								vim.api.nvim_buf_call(b, function()
									vim.cmd("edit!")
								end)
								break
							end
						end

						vim.bo.modified = false
						vim.notify("Re-encrypted to " .. f)
					end,
				})

				vim.api.nvim_create_autocmd("BufUnload", {
					buffer = buf,
					callback = function()
						if vim.bo[buf].modified then
							vim.notify(
								"SOPS buffer closed with unsaved changes — original file unchanged",
								vim.log.levels.WARN
							)
						end
					end,
				})
			elseif subcmd == "decrypt" then
				local f, d, type_flag = sops_file_info()
				local ciphertext = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
				local args = string.format(
					"--decrypt --input-type %s --output-type %s --filename-override %s /dev/stdin",
					type_flag,
					type_flag,
					vim.fn.shellescape(f)
				)
				local decrypted, err = sops_run(d, direnv_exports(d), args, ciphertext)
				if err then
					vim.notify("SOPS decryption failed:\n" .. err, vim.log.levels.ERROR)
					return
				end
				buf_set_lines(decrypted)
				vim.notify("Decrypted in buffer (not saved to disk)")
			elseif subcmd == "encrypt" then
				local f, d, type_flag = sops_file_info()
				local plaintext = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
				local args = string.format(
					"--encrypt --input-type %s --output-type %s --filename-override %s /dev/stdin",
					type_flag,
					type_flag,
					vim.fn.shellescape(f)
				)
				local encrypted, err = sops_run(d, "", args, plaintext)
				if err then
					vim.notify("SOPS encryption failed:\n" .. err, vim.log.levels.ERROR)
					return
				end
				buf_set_lines(encrypted)
				vim.notify("Encrypted in buffer (not saved to disk)")
			else
				vim.notify(
					"Sops: unknown subcommand '" .. (subcmd or "") .. "'. Use edit, decrypt, or encrypt.",
					vim.log.levels.ERROR
				)
			end
		end, {
			nargs = 1,
			complete = function()
				return { "edit", "decrypt", "encrypt" }
			end,
			desc = "SOPS operations: edit | decrypt | encrypt",
		})

		vim.keymap.set("n", "<leader>sd", "<cmd>Sops decrypt<cr>", { desc = "SOPS: decrypt into buffer" })
		vim.keymap.set("n", "<leader>se", "<cmd>Sops encrypt<cr>", { desc = "SOPS: encrypt buffer in place" })
		vim.keymap.set("n", "<leader>sE", "<cmd>Sops edit<cr>", { desc = "SOPS: edit in temp buffer" })
	end,
}
