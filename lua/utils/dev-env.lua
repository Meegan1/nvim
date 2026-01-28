---Check if an executable exists globally or locally
---@param name string The name of the executable to check
---@return string|nil executable_path The path to the executable or nil if not found
local function check_executable(name)
	local global = vim.fn.executable(name)
	if global == 1 then
		return name
	end
	local local_path = vim.fn.glob("node_modules/.bin/" .. name)
	if local_path ~= "" then
		return local_path
	end
	return nil
end

---Check if a library exists and should be included
---@param lib string The library name to check
---@param include? function Function that returns boolean whether to include the library
---@return string|nil library The library name if it exists and should be included
local function check_lib(lib, include)
	if not check_executable(lib) then
		return nil
	end

	if include and not include() then
		return nil
	end

	return lib
end

---Create a filtered table of libraries
---@param lib table The table of libraries to filter
---@param transform? function Optional function to transform the filtered table
---@return table filtered_table The filtered and optionally transformed table
local function create_libs_table(lib, transform)
	local table = vim.tbl_filter(function(v)
		return v ~= nil
	end, lib)

	if transform then
		table = transform(table)
	end

	return table
end

return {
	check_executable = check_executable,
	check_lib = check_lib,
	create_libs_table = create_libs_table,
}
