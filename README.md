# show-key.nvim

A premium, searchable Neovim shortcut viewer popup with manual grouping and modern card-based UI.

![ShowKey Demo](https://via.placeholder.com/800x400?text=ShowKey+UI+Demo) *(Replace with actual screenshot)*

## ✨ Features

- 🔍 **Reactive Search**: Filter shortcuts by title, keys, description, or group as you type.
- 📦 **Manual Grouping**: Organize your keymaps into custom categories.
- 🎨 **Premium UI**: Modern card-based layout with separate Title (Bold) and Description (Italic).
- 🌫️ **Transparency**: Support for transparent backgrounds (winblend).
- ⌨️ **Badges**: Beautifully rendered keybinding badges for clear visibility.
- 🖱️ **Navigation**: Smoothly navigate with `j`/`k` and close with `q`/`Esc`.

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

## 🎨 Highlights
Customize these highlight groups for a unique look:
- `ShowKeyGroup`: Group headers.
- `ShowKeyCardTitle`: Shortcut main title.
- `ShowKeyCardDesc`: Shortcut secondary description.
- `ShowKeyBadge`: Keybinding badges background/foreground.
- `ShowKeySelected`: Active selection row background.
- `ShowKeySearchIcon`: The search icon in the header.

## License
MIT
