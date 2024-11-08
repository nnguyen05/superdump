vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.rust_recommended_style = false
vim.g.python_recommended_style = false

vim.opt.termguicolors = true

vim.cmd("silent! color vim")
vim.cmd("silent! set nowrap")

require("config.lazy")

local cmp = require("cmp")
local lspconfig = require("lspconfig")

cmp.setup({
	snippet = {
		-- REQUIRED - you must specify a snippet engine
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	window = {
		-- completion = cmp.config.window.bordered(),
		-- documentation = cmp.config.window.bordered(),
	},
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		-- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
		["<C-y>"] = cmp.mapping.confirm({ select = true }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "buffer" },
	})
})

cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline({
		["<Up>"] = { c = cmp.mapping.select_prev_item() },
		["<Down>"] = { c = cmp.mapping.select_next_item() },
		["<Left>"] = { c = cmp.mapping.select_prev_item() },
		["<Right>"] = { c = cmp.mapping.select_next_item() },
		["<CR>"] = { c = cmp.mapping.confirm({ select = false }) },
		["<Tab>"] = { c = cmp.mapping.confirm({ select = false }) },
	}),
	sources = cmp.config.sources({
		{ name = "path" },
		{ name = "cmdline" }
	}),
	matching = { disallow_symbol_nonprefix_matching = false }
})

lspconfig.rust_analyzer.setup { }

lspconfig.lua_ls.setup {
	on_init = function(client)
		if client.workspace_folders then
			local path = client.workspace_folders[1].name
			if vim.uv.fs_stat(path.."/.luarc.json") or vim.uv.fs_stat(path.."/.luarc.jsonc") then
				return
			end
		end
		client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
			runtime = {
				-- Tell the language server which version of Lua you"re using
				-- (most likely LuaJIT in the case of Neovim)
				version = "LuaJIT"
			},
			-- Make the server aware of Neovim runtime files
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME
					-- Depending on the usage, you might want to add additional paths here.
					-- "${3rd}/luv/library"
					-- "${3rd}/busted/library",
				}
				-- or pull in all of "runtimepath". NOTE: this is a lot slower and will cause issues when working on your own configuration (see https://github.com/neovim/nvim-lspconfig/issues/3189)
				-- library = vim.api.nvim_get_runtime_file("", true)
			}
		})
	end,
	settings = {
		Lua = {}
	}
}

lspconfig.clangd.setup { }

lspconfig.ts_ls.setup {
	init_options = { hostInfo = "neovim" },
	cmd = {"npx", "typescript-language-server", "--stdio"},
	filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
	},
	root_dir = lspconfig.util.root_pattern("tsconfig.json", "jsconfig.json", "package.json", ".git"),
	single_file_support = true,
}
