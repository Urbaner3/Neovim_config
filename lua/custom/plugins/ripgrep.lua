-- iruzo/ripgrep.nvim: Ripgrep manager for Neovim.
-- Installs its pinned rg release under stdpath('data'), and only prepends it
-- to PATH when no system rg is available. (This machine already has rg, so
-- the plugin is effectively a no-op safety net for other machines.)
vim.pack.add { 'https://github.com/iruzo/ripgrep.nvim' }

-- Reproduce the old lazy `build` step under vim.pack: run the installer after
-- install/update, but only when the system has no rg binary at all.
if vim.fn.executable 'rg' == 0 then
  vim.api.nvim_create_autocmd('PackChanged', {
    desc = 'Install managed ripgrep when system rg is missing',
    callback = function(ev)
      local kind = ev.data.kind
      if ev.data.spec.name == 'ripgrep.nvim' and (kind == 'install' or kind == 'update') then
        require('rg_setup').install_rg()
      end
    end,
  })
end
