-- Formatting with conform.nvim
return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>gf',
      function()
        require('conform').format({ async = true, lsp_fallback = true })
      end,
      mode = '',
      desc = 'Format buffer',
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { 'stylua' },
      swift = { 'swiftformat' },
      -- Add more as needed:
      -- python = { 'black' },
      -- javascript = { 'prettier' },
      -- typescript = { 'prettier' },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
    notify_on_error = true,
  },
}

