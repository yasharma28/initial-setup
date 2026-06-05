-- Entry point. Loads editor config first, then bootstraps lazy.nvim, which
-- loads every spec under lua/plugins/. Kept thin on purpose — wiring only.
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
