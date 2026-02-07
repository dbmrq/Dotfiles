-- Treesitter configuration (new API for nvim-treesitter main branch)
-- Requires Neovim 0.11+
return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
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

      -- Only install missing parsers (avoid recompiling on every startup)
      local missing = {}
      for _, parser in ipairs(parsers) do
        local ok = pcall(vim.treesitter.language.inspect, parser)
        if not ok then
          table.insert(missing, parser)
        end
      end
      if #missing > 0 then
        require('nvim-treesitter').install(missing)
      end

      -- Enable treesitter highlighting for all supported filetypes
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
}
