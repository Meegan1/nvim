-- function to check if file exists from list of files
local function file_exists(files)
	for _, file in ipairs(files) do
		if vim.fn.filereadable(file) == 1 then
			return true
		end
	end
	return false
end

return file_exists
