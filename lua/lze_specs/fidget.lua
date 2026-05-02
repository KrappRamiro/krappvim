return {
	"fidget.nvim",
	auto_enable = true,
	event = "DeferredUIEnter",
	after = function(plugin)
		require("fidget").setup({})
	end,
}
