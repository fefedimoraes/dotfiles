-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_user_command("W", "w", { nargs = 0 }) -- Remap :W to :w
vim.api.nvim_create_user_command("Wa", "wa", { nargs = 0 }) -- Remap :Wa to :wa
vim.api.nvim_create_user_command("Q", "q", { nargs = 0 }) -- Remap :Q to :q
vim.api.nvim_create_user_command("Qa", "qa", { nargs = 0 }) -- Remap :Qa to :qa

if os.getenv("TMUX") then
  --- wraps message with tmux prefix so that the underlying terminal can interpret it correctly
  --- needs 'set-option -g allow-passthrough on' in tmux config
  ---@param content string
  ---@return string
  local function wrap_tmux(content)
    return string.format("\27Ptmux;\27%s\27\\", content)
  end

  local original_ui_send = vim.api.nvim_ui_send

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.api.nvim_ui_send =
    ---@param content string
    function(content)
      original_ui_send(wrap_tmux(content))
    end
end
