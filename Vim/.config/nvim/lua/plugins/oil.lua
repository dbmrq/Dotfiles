-- Oil.nvim - file explorer that lets you edit your filesystem like a buffer
return {
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    -- Use default file explorer (replaces netrw)
    default_file_explorer = true,
    -- Show hidden files by default
    view_options = {
      show_hidden = true,
    },
    -- Columns to display
    columns = {
      'icon',
    },
    -- Skip confirmation for simple operations
    skip_confirm_for_simple_edits = true,
    -- Keymaps in oil buffer (set to false to disable)
    keymaps = {
      ['g?'] = 'actions.show_help',
      ['<CR>'] = 'actions.select',
      ['<C-v>'] = 'actions.select_vsplit',
      ['<C-s>'] = 'actions.select_split',
      ['<C-t>'] = 'actions.select_tab',
      ['<C-p>'] = 'actions.preview',
      ['<C-c>'] = 'actions.close',
      ['<C-l>'] = 'actions.refresh',
      ['-'] = 'actions.parent',
      ['_'] = 'actions.open_cwd',
      ['`'] = 'actions.cd',
      ['~'] = 'actions.tcd',
      ['gs'] = 'actions.change_sort',
      ['gx'] = 'actions.open_external',
      ['g.'] = 'actions.toggle_hidden',
      ['g\\'] = 'actions.toggle_trash',
    },
    -- Float window settings for preview
    float = {
      padding = 2,
      max_width = 0,
      max_height = 0,
      border = 'rounded',
    },
  },
  keys = {
    { '-', '<cmd>Oil<cr>', desc = 'Open parent directory' },
    { '<leader>e', '<cmd>Oil<cr>', desc = 'File explorer' },
  },
}

