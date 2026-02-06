-- LSP Configuration (Neovim 0.11+ native API)
return {
  -- Mason for installing LSP servers
  {
    'williamboman/mason.nvim',
    lazy = false,
    opts = {},
  },

  -- Mason tool installer
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    opts = {
      ensure_installed = {
        'lua-language-server',
        'pyright',
        'typescript-language-server',
        'stylua',
      },
    },
  },

  -- LSP progress indicator
  { 'j-hui/fidget.nvim', opts = {} },

  -- Completion capabilities
  { 'hrsh7th/cmp-nvim-lsp' },
}
