local M = {}

local PYTHON_TAB_NAME = 'python'
local FILES_PANE_NAME = 'files'
local RUN_PANE_NAME = 'run'
local EDITOR_PANE_NAME = 'editor'

local python_root_markers = {
  'pyproject.toml',
  'ruff.toml',
  '.ruff.toml',
  'pytest.ini',
  'tox.ini',
  'setup.py',
  'setup.cfg',
  '.git',
}

local state = {
  last_pytest_cmd = nil,
}

local function root_dir(bufnr)
  return vim.fs.root(bufnr or 0, python_root_markers) or vim.fn.getcwd()
end

local function python_notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = 'Python' })
end

local function python_ide_socket()
  local tmpdir = vim.env.TMPDIR or '/tmp/'
  if not tmpdir:match('/$') then
    tmpdir = tmpdir .. '/'
  end
  local session = (vim.env.ZELLIJ_SESSION_NAME or 'default'):gsub('[^%w_.-]', '_')
  return tmpdir .. 'nvim-python-ide-' .. session .. '.sock'
end

local function run_ruff_action(action)
  vim.lsp.buf.code_action({
    apply = true,
    context = { only = { action } },
  })
end

local function in_zellij()
  return vim.env.ZELLIJ ~= nil and vim.env.ZELLIJ ~= ''
end

local function tab_exists(name)
  local output = vim.fn.system({ 'zellij', 'action', 'query-tab-names' })
  if vim.v.shell_error ~= 0 then
    return false
  end

  for line in output:gmatch('[^\r\n]+') do
    if line == name then
      return true
    end
  end

  return false
end

local function layout_has_named_pane(name)
  local layout = vim.fn.system({ 'zellij', 'action', 'dump-layout' })
  if vim.v.shell_error ~= 0 then
    return false
  end
  return layout:match('name%s*=%s*"' .. name .. '"') ~= nil
end

local function zellij(args)
  vim.fn.system(args)
  return vim.v.shell_error == 0
end

local function resize_current_pane(direction, times)
  for _ = 1, times do
    if not zellij({ 'zellij', 'action', 'resize', 'increase', direction }) then
      break
    end
  end
end

local function ensure_python_ide_server()
  local server = python_ide_socket()
  if vim.v.servername == server then
    return server
  end

  local ok, result = pcall(vim.fn.serverstart, server)
  if not ok then
    return nil, result
  end

  if result == nil or result == '' or result == 0 then
    return nil, vim.v.errmsg
  end

  return server
end

local function open_python_ide(bufnr)
  if not in_zellij() then
    python_notify('PythonIDE works inside Zellij sessions only.', vim.log.levels.WARN)
    return
  end

  local server, err = ensure_python_ide_server()
  if not server then
    if tab_exists(PYTHON_TAB_NAME) then
      zellij({ 'zellij', 'action', 'go-to-tab-name', PYTHON_TAB_NAME })
      python_notify('A Python IDE tab already exists, so I switched to it instead of duplicating your current Neovim buffer.', vim.log.levels.INFO)
      return
    end

    python_notify('Could not claim the Python IDE socket for this Neovim instance: ' .. tostring(err), vim.log.levels.ERROR)
    return
  end

  local cwd = root_dir(bufnr)
  local nnn_opener = (vim.env.HOME or '') .. '/.nnn-opener'
  local created = {}

  zellij({ 'zellij', 'action', 'rename-tab', PYTHON_TAB_NAME })
  zellij({ 'zellij', 'action', 'rename-pane', EDITOR_PANE_NAME })

  if not layout_has_named_pane(FILES_PANE_NAME) then
    if zellij({
      'zellij',
      'run',
      '-d',
      'right',
      '-n',
      FILES_PANE_NAME,
      '--cwd',
      cwd,
      '--',
      'env',
      'NNN_OPENER=' .. nnn_opener,
      'NNN_NVIM_SOCKET=' .. server,
      'nnn',
      '-c',
    }) then
      zellij({ 'zellij', 'action', 'rename-pane', FILES_PANE_NAME })
      zellij({ 'zellij', 'action', 'move-pane', 'left' })
      zellij({ 'zellij', 'action', 'move-focus', 'right' })
      resize_current_pane('left', 4)
      table.insert(created, 'file browser')
    end
  end

  if not layout_has_named_pane(RUN_PANE_NAME) then
    local shell = vim.env.SHELL ~= nil and vim.env.SHELL ~= '' and vim.env.SHELL or '/bin/zsh'
    if zellij({ 'zellij', 'run', '-d', 'down', '-n', RUN_PANE_NAME, '--cwd', cwd, '--', shell, '-i' }) then
      zellij({ 'zellij', 'action', 'rename-pane', RUN_PANE_NAME })
      zellij({ 'zellij', 'action', 'move-focus', 'up' })
      resize_current_pane('down', 4)
      table.insert(created, 'run pane')
    end
  end

  if #created == 0 then
    python_notify('Promoted the current tab into the Python IDE. Use Ctrl-g for Zellij pane mode, then <leader>p inside Neovim.', vim.log.levels.INFO)
    return
  end

  python_notify('Promoted the current tab into the Python IDE and added ' .. table.concat(created, ' + ') .. '. Use Ctrl-g when you want Zellij pane controls.', vim.log.levels.INFO)
end

local function show_help()
  python_notify(table.concat({
    'Press <leader>p to discover Python actions with which-key.',
    'For long-running app/repl/log commands in Zellij, use: runpane',
    '',
    'Keymaps:',
    '  <leader>pa  pytest all',
    '  <leader>pf  pytest file',
    '  <leader>pn  pytest nearest test',
    '  <leader>pl  pytest last command',
    '  <leader>pi  organize imports (Ruff)',
    '  <leader>px  fix auto-fixable issues (Ruff)',
    '  <leader>po  open Python IDE layout',
    '  <leader>ph  show this help',
    '',
    'Commands:',
    '  :Pytest  :PytestFile  :PytestNearest  :PytestLast',
    '  :PythonImports  :PythonFixAll  :PythonIDE  :PythonHelp',
    '',
    'Zellij:',
    '  runpane  open/focus bottom run pane for long-lived commands',
    '  :PythonIDE / <leader>po promotes the current tab into the Python IDE',
    '  selecting a .py file from nnn reuses or creates the dedicated python tab',
  }, '\n'))
end

local function nearest_test_target(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == '' then
    return nil
  end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, cursor_line, false)
  local test_name, test_indent

  for i = #lines, 1, -1 do
    local indent, name = lines[i]:match('^(%s*)def%s+(test_[A-Za-z0-9_]+)')
    if name then
      test_name = name
      test_indent = #indent
      break
    end
  end

  if not test_name then
    return nil
  end

  local class_name
  for i = #lines, 1, -1 do
    local indent, name = lines[i]:match('^(%s*)class%s+(Test[A-Za-z0-9_]+)')
    if name and #indent < test_indent then
      class_name = name
      break
    end
  end

  if class_name then
    return table.concat({ file, class_name, test_name }, '::')
  end

  return table.concat({ file, test_name }, '::')
end

local function pytest_base_command()
  if vim.fn.executable('pytest') == 1 then
    return { 'pytest' }
  end
  if vim.fn.executable('python') == 1 then
    return { 'python', '-m', 'pytest' }
  end
  if vim.fn.executable('python3') == 1 then
    return { 'python3', '-m', 'pytest' }
  end
end

local function open_pytest_terminal(cmd, cwd)
  if vim.bo.modified and vim.api.nvim_buf_get_name(0) ~= '' then
    vim.cmd('silent write')
  end

  state.last_pytest_cmd = vim.deepcopy(cmd)

  vim.cmd('botright 12new')
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buflisted = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'

  vim.fn.termopen(cmd, {
    cwd = cwd,
    on_exit = function(_, code)
      vim.schedule(function()
        local level = code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
        python_notify((code == 0 and 'Pytest passed:' or 'Pytest failed:') .. ' ' .. table.concat(cmd, ' '), level)
      end)
    end,
  })
end

local function run_pytest(target)
  local cmd = pytest_base_command()
  if not cmd then
    python_notify('Could not find pytest, python, or python3 in PATH.', vim.log.levels.ERROR)
    return
  end

  if target and target ~= '' then
    table.insert(cmd, target)
  end

  open_pytest_terminal(cmd, root_dir(vim.api.nvim_get_current_buf()))
end

local function rerun_last_pytest()
  if not state.last_pytest_cmd then
    python_notify('No previous pytest command yet. Try <leader>pa, <leader>pf, or <leader>pn first.', vim.log.levels.WARN)
    return
  end
  open_pytest_terminal(vim.deepcopy(state.last_pytest_cmd), root_dir(vim.api.nvim_get_current_buf()))
end

local function register_python_buffer(bufnr)
  if vim.b[bufnr].python_workflow_registered then
    return
  end
  vim.b[bufnr].python_workflow_registered = true

  local map = function(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
  end

  map('<leader>ph', show_help, 'Python help')
  map('<leader>pa', function() run_pytest() end, 'Pytest all')
  map('<leader>pf', function() run_pytest(vim.api.nvim_buf_get_name(bufnr)) end, 'Pytest file')
  map('<leader>pn', function()
    local target = nearest_test_target(bufnr)
    if not target then
      python_notify('Could not find a test under the cursor.', vim.log.levels.WARN)
      return
    end
    run_pytest(target)
  end, 'Pytest nearest')
  map('<leader>pl', rerun_last_pytest, 'Pytest last')
  map('<leader>pi', function() run_ruff_action('source.organizeImports.ruff') end, 'Python imports')
  map('<leader>px', function() run_ruff_action('source.fixAll.ruff') end, 'Python fix all')
  map('<leader>po', function() open_python_ide(bufnr) end, 'Open Python IDE')

  vim.api.nvim_buf_create_user_command(bufnr, 'PythonHelp', show_help, { desc = 'Show Python workflow help' })
  vim.api.nvim_buf_create_user_command(bufnr, 'PythonIDE', function()
    open_python_ide(bufnr)
  end, { desc = 'Open the Zellij Python IDE layout' })
  vim.api.nvim_buf_create_user_command(bufnr, 'Pytest', function() run_pytest() end, { desc = 'Run pytest for the project' })
  vim.api.nvim_buf_create_user_command(bufnr, 'PytestFile', function()
    run_pytest(vim.api.nvim_buf_get_name(bufnr))
  end, { desc = 'Run pytest for the current file' })
  vim.api.nvim_buf_create_user_command(bufnr, 'PytestNearest', function()
    local target = nearest_test_target(bufnr)
    if not target then
      python_notify('Could not find a test under the cursor.', vim.log.levels.WARN)
      return
    end
    run_pytest(target)
  end, { desc = 'Run pytest for the nearest test' })
  vim.api.nvim_buf_create_user_command(bufnr, 'PytestLast', rerun_last_pytest, { desc = 'Re-run the last pytest command' })
  vim.api.nvim_buf_create_user_command(bufnr, 'PythonImports', function()
    run_ruff_action('source.organizeImports.ruff')
  end, { desc = 'Organize Python imports with Ruff' })
  vim.api.nvim_buf_create_user_command(bufnr, 'PythonFixAll', function()
    run_ruff_action('source.fixAll.ruff')
  end, { desc = 'Fix auto-fixable Python issues with Ruff' })

  local ok, which_key = pcall(require, 'which-key')
  if ok then
    which_key.add({
      { '<leader>p', group = 'Python', buffer = bufnr },
    })
  end

  vim.schedule(function()
    local notify_once = vim.notify_once or vim.notify
    notify_once('Python ready: <leader>p for tests/Ruff, <leader>po or :PythonIDE promotes this tab into the Python IDE, and selecting .py in nnn reuses the python tab.', vim.log.levels.INFO, { title = 'Python' })
  end)
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  callback = function(event)
    register_python_buffer(event.buf)
  end,
})

M.show_help = show_help
M.open_python_ide = open_python_ide

return M