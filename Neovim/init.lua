local vim = vim

local plug = vim.fn["plug#"]
vim.call("plug#begin")
	plug("neovim/nvim-lspconfig")
	plug("hrsh7th/cmp-nvim-lsp")
	plug("hrsh7th/cmp-buffer")
	plug("hrsh7th/cmp-path")
	plug("hrsh7th/cmp-cmdline")
	plug("hrsh7th/nvim-cmp")
	plug("L3MON4D3/LuaSnip")
	plug("saadparwaiz1/cmp_luasnip")
	
	plug("udalov/kotlin-vim")
vim.call("plug#end")

vim.cmd("silent! color vim")
vim.cmd("silent! set nowrap")

local cmp = require("cmp")
cmp.setup({
	snippet = {
		expand = function(args)
			require('luasnip').lsp_expand(args.body)
		end,
	},
	window = {
		-- completion = cmp.config.window.bordered(),
		-- documentation = cmp.config.window.bordered(),
	},
	mapping = cmp.mapping.preset.insert({
		['<C-b>'] = cmp.mapping.scroll_docs(-4),
		['<C-f>'] = cmp.mapping.scroll_docs(4),
		['<C-Space>'] = cmp.mapping.complete(),
		['<C-e>'] = cmp.mapping.abort(),
		['<C-y>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
	}),
	sources = cmp.config.sources({
		{ name = 'nvim_lsp' },
		{ name = 'luasnip' },
	}, {
		{ name = 'buffer' },
	})
})

local lspconfig = require("lspconfig")
lspconfig.kotlin_language_server.setup{
	cmd = { [[C:\Users\Public\lsp\kotlin-language-server\bin\kotlin-language-server.bat]] },
	init_options = {
		storagePath = lspconfig.util.path.join(vim.env.XDG_DATA_HOME, "nvim-data"),
		-- there is nothing
	},
	root_dir = lspconfig.util.root_pattern(
		"pom.xml"
	)
}
