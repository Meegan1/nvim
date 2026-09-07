-- Utilities for navigating files reported by `git status`

---Get the sorted list of absolute paths for files with changes in `git status`
---(staged, unstaged, and untracked), along with the repo root.
---@return string[]|nil files Absolute paths of changed files, or nil on error
---@return string|nil root Absolute path to the git repo root
local function git_status_files()
	local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if vim.v.shell_error ~= 0 or not root then
		vim.notify("Not a git repository", vim.log.levels.WARN)
		return nil, nil
	end

	local lines = vim.fn.systemlist("git -C " .. vim.fn.shellescape(root) .. " status --porcelain=v1")
	if vim.v.shell_error ~= 0 then
		vim.notify("Failed to get git status", vim.log.levels.WARN)
		return nil, nil
	end

	local files = {}
	local seen = {}
	for _, line in ipairs(lines) do
		-- Format: "XY path" or "XY old -> new" for renames
		local path = line:sub(4)
		local arrow = path:find(" -> ")
		if arrow then
			path = path:sub(arrow + 4)
		end
		-- Strip quotes git adds around paths with special characters
		path = path:gsub('^"(.*)"$', "%1")

		local abspath = root .. "/" .. path
		if not seen[abspath] then
			seen[abspath] = true
			table.insert(files, abspath)
		end
	end

	table.sort(files)

	if #files == 0 then
		vim.notify("No changed files in git status", vim.log.levels.INFO)
		return nil, nil
	end

	return files, root
end

---Open the next/previous file (relative to the current buffer) from `git status`.
---@param direction integer 1 for next, -1 for previous
local function goto_git_status_file(direction)
	local files = git_status_files()
	if not files then
		return
	end

	local current = vim.fn.expand("%:p")
	local idx = nil
	for i, f in ipairs(files) do
		if f == current then
			idx = i
			break
		end
	end

	local next_idx
	if idx == nil then
		next_idx = direction > 0 and 1 or #files
	else
		next_idx = idx + direction
		if next_idx < 1 then
			vim.notify("Already at the first file in git status", vim.log.levels.WARN)
			return
		elseif next_idx > #files then
			vim.notify("Already at the last file in git status", vim.log.levels.WARN)
			return
		end
	end

	vim.cmd("edit " .. vim.fn.fnameescape(files[next_idx]))
end

return {
	git_status_files = git_status_files,
	goto_git_status_file = goto_git_status_file,
}
