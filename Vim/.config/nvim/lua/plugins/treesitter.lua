-- Treesitter configuration (new API for nvim-treesitter main branch)
-- Requires Neovim 0.11+
return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      -- Install parsers
      local parsers = {
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
        'swift',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
      }

      -- Install parsers asynchronously
      require('nvim-treesitter').install(parsers)

      -- Enable treesitter highlighting for all supported filetypes
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          -- Check if parser exists for this filetype
          local ok = pcall(vim.treesitter.start, args.buf)
          if not ok then
            return
          end
        end,
      })
    end,
  },
}
