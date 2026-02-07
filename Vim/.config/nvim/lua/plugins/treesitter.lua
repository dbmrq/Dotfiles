-- Treesitter configuration (using stable master branch)
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'bash',
          'c',
          'diff',
          'html',
          'javascript',
          'json',
          'lua',
          'luadoc',
          'markdown',
          'markdown_inline',
          'python',
          'query',
          'regex',
          'tsx',
          'typescript',
          'vim',
          'vimdoc',
          'yaml',
        },
        auto_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
