# show-key.nvim

A premium, searchable Neovim shortcut viewer popup with manual grouping and modern card-based UI.

![ShowKey Demo](https://via.placeholder.com/800x400?text=ShowKey+UI+Demo) *(Replace with actual screenshot)*

## ✨ Features

- 🔍 **Reactive Search**: Filter shortcuts by title, keys, description, or group as you type.
- 📦 **Manual Grouping**: Organize your keymaps into custom categories.
- 🎨 **Premium UI**: Modern 2-column grid with individual card borders and key-cap styles.
- 󰌌 **Fixed Header**: Sticky header with centered title and search box.
- 🌫️ **Transparency**: Support for transparent backgrounds.
- 🖱️ **Navigation**: Grid-based navigation (`h`/`j`/`k`/`l`) and auto-close on focus leave.

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "your-username/show-key.nvim",
  -- If using local development
  -- dir = "/path/to/show-key.nvim", 
  opts = {
    title = "My Shortcuts",
    shortcuts = {
      { 
        title = "Find Files",
        keys = "<leader>ff", 
        desc = "Search files using Telescope", 
        group = "Files" 
      },
      { 
        title = "Git Status",
        keys = "<leader>gs", 
        desc = "Open Neogit status buffer", 
        group = "Git" 
      },
    }
  },
  config = function(_, opts)
    require("show-key").setup(opts)
  end,
}
```

## ⚙️ Configuration

```lua
require("show-key").setup({
  title = "Neovim Shortcuts",
  border = "rounded", -- "none", "single", "double", "rounded", "solid", "shadow"
  position = "center",
  width = 0.8,
  height = 0.8,
  shortcuts = {}, -- List of shortcuts to register on setup
})
```

## 🚀 Usage

### Command
Run `:ShowKey` to open the popup.

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
- `j` / `k`: Move selection down/up.
- `[any printable char]`: Filter list (searches titles, keys, and descriptions).
- `<BS>`: Delete last search character.
- `<Esc>` / `q`: Close the popup.

## 🎨 Customization (Styles)

You can fully customize the colors and styles of the popup in your `setup` function:

```lua
require("show-key").setup({
  styles = {
    header = { fg = "#7aa2f7", bold = true },
    group = { fg = "#bb9af7", bold = true },
    card_title = { fg = "#c0caf5", bold = true },
    card_desc = { fg = "#565f89", italic = true },
    badge = { bg = "#3b4261", fg = "#7aa2f7", bold = true }, -- The [...] shortcut keys
    border = { fg = "#7aa2f7" }, -- Main window and card borders
    selected_border = { fg = "#bb9af7", bold = true }, -- Highlighted card border
    search_icon = { fg = "#7aa2f7" },
  }
})
```

## License
MIT
