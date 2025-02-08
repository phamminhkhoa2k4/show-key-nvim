# show-key.nvim

A premium, searchable Neovim shortcut viewer popup with manual grouping and modern card-based UI.

![ShowKey Demo](./images/thumbnail.png) 

## ✨ Features

- 🔍 **Reactive Search**: Filter shortcuts by title, keys, description, or group as you type.
- 📦 **Manual Grouping**: Organize your keymaps into custom categories.
- 🎨 **Premium UI**: Modern 2-column grid with individual card borders and key-cap styles.
- 󰌌 **Fixed Header**: Sticky header with centered title and search box.
- 🌫️ **Transparency**: Support for transparent backgrounds.
- 🖱️ **Navigation**: Grid-based navigation (`h`/`j`/`k`/`l`) and auto-close on focus leave.

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
  "phamminhkhoa2k4/show-key-nvim",
  opts = {
    title = "My Neovim Shortcuts",
    transparent = true,
    width = 0.8,
    height = 0.7,
    -- Custom styles
    styles = {
      badge = { bg = "#3b4261", fg = "#ff9e64", bold = true },
      key_bracket = { fg = "#7aa2f7" },
    },
    -- Initial shortcuts
    shortcuts = {
      { title = "Find Files", keys = "<leader>ff", desc = "Telescope find files", group = "Files" },
      { title = "Live Grep", keys = "<leader>fg", desc = "Search text", group = "Files" },
    }
  }
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
  'phamminhkhoa2k4/show-key-nvim',
  config = function()
    require('show-key').setup({
      title = "My Shortcuts",
      shortcuts = {
        { title = "Save File", keys = "<C-s>", desc = "Quick save" },
      },
      styles = {
        badge = { bg = "#2e3440", fg = "#88c0d0" }
      }
    })
  end
}
```

### [pckr.nvim](https://github.com/lewis6991/pckr.nvim)
```lua
{
  'phamminhkhoa2k4/show-key-nvim',
  config = function()
    require('show-key').setup({
        title = "Shortcuts",
        width = 0.7
    })
  end
};
```

### [paq-nvim](https://github.com/savq/paq-nvim)
```lua
paq { 'phamminhkhoa2k4/show-key-nvim' }

-- In your init.lua
require('show-key').setup({
    title = "My Shortcuts"
})
```

## ⚙️ Configuration

The plugin comes with sensible defaults. You only need to provide the `shortcuts` list to get started.

```lua
require("show-key").setup({
  title = "Neovim Shortcuts", -- Popup header title
  transparent = true,          -- Use transparent background
  width = 0.8,                 -- Width percentage (0.1 - 1.0)
  height = 0.8,                -- Height percentage (0.1 - 1.0)
  border = "rounded",          -- "rounded" (default) or "none"
  shortcuts = {},              -- List of shortcuts to register on setup
})
```

## 🎨 Customization (Styles)

You can fully customize the colors and typography of every UI element. This allows you to match your favorite colorscheme (TokyoNight, Catppuccin, etc.):

```lua
require("show-key").setup({
  styles = {
    header = { fg = "#7aa2f7", bold = true },           -- Popup title
    group = { fg = "#bb9af7", bold = true },            -- Group headers
    card_title = { fg = "#c0caf5", bold = true },       -- Keymap title
    card_desc = { fg = "#565f89", italic = true },      -- Keymap description
    badge = { bg = "#3b4261", fg = "#c0caf5", bold = true }, -- The key-cap text
    key_bracket = { fg = "#7aa2f7" },                   -- The [ and ] brackets
    border = { fg = "#7aa2f7" },                        -- Card and window borders
    selected_border = { fg = "#bb9af7", bold = true },  -- Highlighted card border
    search_icon = { fg = "#7aa2f7" },                   -- Search glass icon
  }
})
```

## 🚀 Usage

### Commands
- `:ShowKey`: Open the shortcut viewer popup.
- `:ShowKeyRegister`: Open the interactive form to create and register a new shortcut.

### Shortcut Creator (Form)
Don't want to edit your config? Use `:ShowKeyRegister` to open an interactive form.

- **Fields**: Title, Keys, Description, Group.
- **Controls**:
    - `<Tab>` / `<S-Tab>`: Move between fields.
    - `[Type]`: Enter text into the active field.
    - `<BS>`: Delete text.
    - `<Enter>`: Save and register the shortcut.
    - `<Esc>` / `q`: Cancel and close.

### Manual Registration
You can also register shortcuts after setup:

```lua
require("show-key").register_shortcuts({
  { 
    title = "Find Files",
    keys = "<leader>ff", 
    desc = "Telescope find_files", 
    group = "File Management", 
  },
  { 
    title = "Git Status",
    keys = "<leader>gs", 
    desc = "Open Neogit dashboard", 
    group = "Git Operations", 
  },
})
```

### Controls in Popup
- `h` / `j` / `k` / `l`: Navigate the grid.
- `x`: **Delete** the selected shortcut.
- `[any printable char]`: Filter list (searches titles, keys, and descriptions).
- `<BS>`: Delete last search character.
- `<Esc>` / `q`: Close the popup.

## License
MIT
