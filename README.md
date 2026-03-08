# qmk.nvim

A modern Neovim plugin for compiling [QMK](https://qmk.fm/) firmware, written in pure Lua.

## Features

- **Compile** your current keyboard/keymap with a single keymap
- **Interactive picker** to select keyboard and keymap (works great with `dressing.nvim` or `telescope-ui-select`)
- **Quickfix integration** — errors and warnings land in the quickfix list with file/line jumping
- **Persistent selection** — remembers your last keyboard/keymap between sessions
- **Async** — compile runs in the background, Neovim stays responsive

## Requirements

- Neovim ≥ 0.9
- [QMK CLI](https://docs.qmk.fm/#/newbs_getting_started) installed and on `$PATH`
- QMK firmware cloned locally

## Installation

### lazy.nvim

```lua
{
  "you/qmk.nvim",
  config = function()
    require("qmk").setup({
      qmk_path = vim.fn.expand("~/qmk_firmware"), -- path to your QMK clone
    })
  end,
}
```

### packer.nvim

```lua
use {
  "you/qmk.nvim",
  config = function()
    require("qmk").setup()
  end,
}
```

## Configuration

All options with their defaults:

```lua
require("qmk").setup({
  -- Path to your QMK firmware directory
  qmk_path = vim.fn.expand("~/qmk_firmware"),

  -- Pre-set a keyboard (optional — picker will prompt if nil)
  keyboard = nil,

  -- Pre-set a keymap (optional — picker will prompt if nil)
  keymap = nil,

  -- Parallel make jobs. 0 = use all available CPU cores.
  make_jobs = 0,

  -- Automatically open the quickfix window after compiling
  auto_open_qf = true,

  -- Key mappings (set any to false to disable)
  keymaps = {
    compile        = "<leader>qc",   -- QMKCompile
    compile_select = "<leader>qs",   -- QMKCompileSelect
    open_qf        = "<leader>qq",   -- QMKOpenQF
  },
})
```

## Commands

| Command             | Description                                      |
|---------------------|--------------------------------------------------|
| `:QMKCompile`       | Compile the last-used (or configured) keyboard/keymap |
| `:QMKCompileSelect` | Open interactive picker, then compile            |
| `:QMKOpenQF`        | Re-open the quickfix window                      |

## Quickfix Navigation

After a compile, use standard Neovim quickfix keys:

| Key      | Action                        |
|----------|-------------------------------|
| `]q`     | Next error / warning          |
| `[q`     | Previous error / warning      |
| `:cfirst`| Jump to first error           |
| `:cn`    | Next item                     |
| `:cp`    | Previous item                 |

## Optional Enhancements

The picker uses `vim.ui.select` — drop in either of these for a richer UI:

- [dressing.nvim](https://github.com/stevearc/dressing.nvim) — renders `vim.ui.select` with Telescope or fzf
- [telescope-ui-select.nvim](https://github.com/nvim-telescope/telescope-ui-select.nvim)

## Project Structure

```
qmk.nvim/
├── plugin/
│   └── qmk.lua          # Auto-loaded entry point
├── lua/
│   └── qmk/
│       ├── init.lua      # setup(), config
│       ├── compile.lua   # Async compile + quickfix parsing
│       ├── selector.lua  # Interactive keyboard/keymap picker
│       ├── commands.lua  # :QMKCompile, :QMKCompileSelect, :QMKOpenQF
│       ├── keymaps.lua   # Key binding registration
│       └── cache.lua     # Persist last keyboard/keymap to disk
└── doc/
    └── qmk.txt           # Vim help file
```
