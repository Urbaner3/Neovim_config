-- Custom plugins loader (vim.pack style, Neovim 0.12+).
-- Every other *.lua file in this directory is executed for its side effects:
-- call `vim.pack.add { ... }` directly in each file. Return values are ignored
-- (there is no lazy.nvim spec handling here).

-- Iterate over all Lua files in the plugins directory and load them
local plugins_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'plugins')
for file_name, type in vim.fs.dir(plugins_dir) do
  if type == 'file' and file_name:match '%.lua$' and file_name ~= 'init.lua' then
    local module = file_name:gsub('%.lua$', '')
    require('custom.plugins.' .. module)
  end
end
