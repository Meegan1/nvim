--- Checks if a given path is a directory.
-- @param path The path to check.
-- @return boolean True if the path is a directory, false otherwise.
local function is_directory(path)
  local p = io.popen('test -d "' .. path .. '" && echo "yes" || echo "no"')
  local result = p:read("*a")
  p:close()
  return result:match("yes") ~= nil
end

-- Recursively requires Lua files in a directory matching a given filename.
-- @param dir The directory to search for files.
-- @param filename The name of the file to match.
local function require_files(dir, filename)
  -- append .lua to filename if it doesn't have an extension
  if not filename:match("%.") then
    filename = filename .. ".lua"
  end

  local lua_dir = vim.fn.stdpath("config") .. "/lua/"

  -- Prepend lua/ to the directory if it doesn't start with lua/
  if not dir:match("^" .. lua_dir) then
    dir = lua_dir .. dir
  end

  for file in io.popen('ls "' .. dir .. '"'):lines() do
    if file ~= "." and file ~= ".." then
      local full_path = dir .. "/" .. file
      if is_directory(full_path) then
        require_files(full_path, filename)
      elseif file == filename then
        -- Convert the full path to a proper require path
        local module_path = full_path:sub(lua_dir:len() + 1) -- Remove the lua/ prefix
        module_path = module_path:gsub("%.lua$", "")     -- Remove .lua extension
        module_path = module_path:gsub("/", ".")         -- Convert slashes to dots

        require(module_path)
      end
    end
  end
end

return require_files
