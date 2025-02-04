# show-key.nvim

A premium, searchable Neovim shortcut popup with automatic keymap detection and grouping.

![ShowKey Demo](https://via.placeholder.com/800x400?text=ShowKey+UI+Demo) *(Replace with actual screenshot)*

## ✨ Features

- 🔍 **Reactive Search**: Filter shortcuts by keys, description, or group as you type.
- 📦 **Smart Grouping**: Automatically groups keymaps by prefix (Leader, Go, etc.) or manual category.
- 🤖 **Auto-Detection**: Scans your existing Neovim keymaps (global and buffer-local) that have a description.
- 🎨 **Premium UI**: Modern card-based layout with syntax highlighting and key badges.
- ⌨️ **Quick Execution**: Navigate with `j`/`k` and press `Enter` to run the shortcut.

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "your-username/show-key.nvim",
  config = function()
    require("show-key").setup({
      -- your configuration here
    })
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
  auto_detect = true, -- Auto-scan existing keymaps
})
```

## 🚀 Usage

### Command
Run `:ShowKey` to open the popup.

### Manual Registration
You can register custom shortcut groups in your `init.lua`:

```lua
require("show-key").register_shortcuts({
  { 
    keys = "<leader>ff", 
    desc = "Find Files", 
    group = "File Management", 
    action = "Telescope find_files" 
  },
  { 
    keys = "<leader>gs", 
    desc = "Git Status", 
    group = "Git Operations", 
    action = function() print("Opening Git Status...") end 
  },
})
```

### Controls in Popup
- `j` / `k`: Move selection down/up.
- `<Enter>`: Execute the selected shortcut and close.
- `<Esc>` / `q`: Close the popup.
- `[any printable char]`: Filter list.
- `<BS>`: Delete last search character.

## 🎨 Highlights
You can customize the colors by overriding these highlight groups:
- `ShowKeyGroup`: Group headers.
- `ShowKeyCardTitle`: Shortcut description.
- `ShowKeyBadge`: Keybinding badges.
- `ShowKeySelected`: Selected card background.
- `ShowKeySearchIcon`: The search icon in the header.

## License
MIT
