-- lua/qmk/compile.lua
local M = {}

local function notify(msg, level)
  vim.notify("[qmk] " .. msg, level or vim.log.levels.INFO)
end

--- Parse QMK output lines into quickfix entries
---@param lines string[]
---@param qmk_path string
---@return table[]
local function parse_qf(lines, qmk_path)
  local items = {}
  -- Patterns: gcc errors/warnings, make errors
  local patterns = {
    -- file:line:col: error/warning: msg
    { pat = "^(.+):(%d+):(%d+):%s*(error):%s*(.+)$",   type = "E" },
    { pat = "^(.+):(%d+):(%d+):%s*(warning):%s*(.+)$", type = "W" },
    -- file:line: error/warning: msg  (no col)
    { pat = "^(.+):(%d+):%s*(error):%s*(.+)$",          type = "E", nocol = true },
    { pat = "^(.+):(%d+):%s*(warning):%s*(.+)$",        type = "W", nocol = true },
  }

  for _, line in ipairs(lines) do
    local matched = false
    for _, p in ipairs(patterns) do
      local captures
      if p.nocol then
        local f, l, _, txt = line:match(p.pat)
        if f then
          captures = { filename = f, lnum = tonumber(l), col = 0, text = txt, type = p.type }
        end
      else
        local f, l, c, _, txt = line:match(p.pat)
        if f then
          captures = { filename = f, lnum = tonumber(l), col = tonumber(c), text = txt, type = p.type }
        end
      end

      if captures then
        -- Make path absolute relative to qmk_path if needed
        if not captures.filename:match("^/") then
          captures.filename = qmk_path .. "/" .. captures.filename
        end
        table.insert(items, captures)
        matched = true
        break
      end
    end

    -- Catch bare make errors too
    if not matched and line:match("^make.*Error") then
      table.insert(items, { text = line, type = "E" })
    end
  end
  return items
end

--- Run the compile job
---@param keyboard string
---@param keymap string
---@param cfg table
function M.run(keyboard, keymap, cfg)
  local qmk_path = cfg.qmk_path

  if vim.fn.isdirectory(qmk_path) == 0 then
    notify("QMK path not found: " .. qmk_path, vim.log.levels.ERROR)
    return
  end

  local jobs_flag = cfg.make_jobs == 0
      and ("-j" .. vim.loop.available_parallelism())
      or ("-j" .. cfg.make_jobs)

  local target = keyboard .. ":" .. keymap
  local cmd = string.format(
    "cd %s && qmk compile -kb %s -km %s 2>&1",
    vim.fn.shellescape(qmk_path),
    vim.fn.shellescape(keyboard),
    vim.fn.shellescape(keymap)
  )

  notify(string.format("Compiling %s … (this may take a while)", target))

  -- Clear previous quickfix
  vim.fn.setqflist({}, "r", { title = "QMK: " .. target, items = {} })

  local output_lines = {}
  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    stderr_buffered = false,

    on_stdout = function(_, data)
      if not data then return end
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(output_lines, line)
        end
      end
    end,

    on_stderr = function(_, data)
      if not data then return end
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(output_lines, line)
        end
      end
    end,

    on_exit = function(_, exit_code)
      local qf_items = parse_qf(output_lines, qmk_path)

      -- Always add raw output as text entries if no structured items parsed
      if #qf_items == 0 then
        for _, line in ipairs(output_lines) do
          table.insert(qf_items, { text = line })
        end
      end

      vim.fn.setqflist({}, "r", {
        title = "QMK: " .. target,
        items = qf_items,
      })

      if exit_code == 0 then
        notify(string.format("✓ Compiled %s successfully", target), vim.log.levels.INFO)
        -- Still open qf so user can review output
        if cfg.auto_open_qf then
          vim.cmd("copen")
        end
      else
        notify(string.format("✗ Compile failed for %s", target), vim.log.levels.ERROR)
        if cfg.auto_open_qf then
          vim.cmd("copen")
        end
        -- Jump to first error
        local errors = vim.tbl_filter(function(i) return i.type == "E" end, qf_items)
        if #errors > 0 then
          vim.cmd("cfirst")
        end
      end
    end,
  })

  if job_id <= 0 then
    notify("Failed to start compile job", vim.log.levels.ERROR)
  end
end

return M
