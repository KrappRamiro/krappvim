return {
	{
		-- lze specs need a name, so this string is just made up
		-- This spec here loads the value of config.settings.colorscheme and passes it into vim.cmd.colorscheme
		"trigger_colorscheme",
		event = "VimEnter",
		load = function(_name)
			-- schedule so it runs after VimEnter
			vim.schedule(function()
				-- nixInfo gets settings.colorscheme from Nix, if not available, uses onedark_dark
				vim.cmd.colorscheme(nixInfo("onedark_dark", "settings", "colorscheme"))
				vim.schedule(function()
					-- Overwrites the numbers color with a purple
					vim.cmd([[hi LineNr guifg=#bb9af7]])
				end)
			end)
		end,
	},
	{
		-- NOTE: view these names in the info plugin!
		-- :lua nixInfo.lze.debug.display(nixInfo.plugins)
		-- The display function is from lzextras
		"onedarkpro.nvim",
		auto_enable = true,
		colorscheme = { "onedark", "onedark_dark", "onedark_vivid", "onelight" },
	},
	{
		"vim-moonfly-colors",
		auto_enable = true,
		colorscheme = "moonfly",
	},
}
