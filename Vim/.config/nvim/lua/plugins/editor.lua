-- Editor enhancements
return {
  -- File icons
  { 'echasnovski/mini.icons', version = '*', opts = {} },

  -- Which-key for keybinding hints
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 500,
      icons = { mappings = false },
      spec = {
        { '<leader>f', group = 'Find' },
        { '<leader>g', group = 'Git/Format' },
        { '<leader>d', group = 'Document/Delete' },
        { '<leader>w', group = 'Workspace/Window' },
        { '<leader>t', group = 'Toggle' },
        { '<leader>c', group = 'Code/Change' },
        { '<leader>r', group = 'Rename/Replace' },
      },
    },
  },

  -- Git signs in gutter
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  -- Surround text objects
  {
    'kylechui/nvim-surround',
    version = '*',
    event = 'VeryLazy',
    opts = {},
  },

  -- Comment toggling
  {
    'numToStr/Comment.nvim',
    opts = {},
  },

  -- Auto pairs
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    dependencies = { 'hrsh7th/nvim-cmp' },
    config = function()
      require('nvim-autopairs').setup({})
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      local cmp = require('cmp')
      cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
    end,
  },

  -- Text objects (works in both Vim and nvim)
  { 'kana/vim-textobj-user' },
  { 'kana/vim-textobj-entire', dependencies = { 'kana/vim-textobj-user' } },

  -- Exchange text (works in both vim and nvim)
  { 'tommcdo/vim-exchange' },

  -- Readline-style insert mode bindings (C-a, C-e, M-f, M-b, etc.)
  { 'tpope/vim-rsi' },

  -- Highlight todo comments
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },

  -- Indent guides
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {},
  },

  -- Better diagnostics list
  {
    'folke/trouble.nvim',
    opts = {},
    cmd = 'Trouble',
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics (Trouble)' },
      { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics' },
      { '<leader>cs', '<cmd>Trouble symbols toggle focus=false<cr>', desc = 'Symbols (Trouble)' },
      { '<leader>cl', '<cmd>Trouble lsp toggle focus=false win.position=right<cr>', desc = 'LSP Definitions' },
      { '<leader>xL', '<cmd>Trouble loclist toggle<cr>', desc = 'Location List' },
      { '<leader>xQ', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix List' },
    },
  },

  -- Lua development helper
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
}
