-- Telescope fuzzy finder
return {
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable('make') == 1
        end,
      },
      'nvim-telescope/telescope-ui-select.nvim',
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup({
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      })

      -- Enable extensions if installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require('telescope.builtin')
      local map = vim.keymap.set

      -- File pickers
      map('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
      map('n', '<leader>fg', builtin.live_grep, { desc = 'Find by grep' })
      map('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
      map('n', '<leader>fh', builtin.help_tags, { desc = 'Find help' })
      map('n', '<leader>fr', builtin.oldfiles, { desc = 'Find recent files' })
      map('n', '<leader>fw', builtin.grep_string, { desc = 'Find current word' })
      map('n', '<leader>fd', builtin.diagnostics, { desc = 'Find diagnostics' })
      map('n', '<leader>fc', builtin.resume, { desc = 'Find continue (resume)' })

      -- Git pickers
      map('n', '<leader>gs', builtin.git_status, { desc = 'Git status' })
      map('n', '<leader>gc', builtin.git_commits, { desc = 'Git commits' })
      map('n', '<leader>gb', builtin.git_branches, { desc = 'Git branches' })

      -- Search in current buffer
      map('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({
          winblend = 10,
          previewer = false,
        }))
      end, { desc = 'Fuzzy search in buffer' })

      -- Search in open files
      map('n', '<leader>f/', function()
        builtin.live_grep({
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        })
      end, { desc = 'Find in open files' })

      -- Search Neovim config files
      map('n', '<leader>fn', function()
        builtin.find_files({ cwd = vim.fn.stdpath('config') })
      end, { desc = 'Find Neovim config files' })
    end,
  },
}
