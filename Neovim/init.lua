vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.rust_recommended_style = false
-- God is weeping
vim.g.python_recommended_style = true -- false

vim.opt.termguicolors = true

vim.cmd("silent! color vim")
vim.cmd("silent! set nowrap")

require("config.lazy")

local cmp = require("cmp")
local lspconfig = require("lspconfig")
local dap = require("dap")
local dapui = require("dapui")
local secrets = require("config.secrets")

function PrintDiagnostics(opts, bufnr, line_nr, client_id)
	bufnr = bufnr or 0
	line_nr = line_nr or (vim.api.nvim_win_get_cursor(0)[1] - 1)
	opts = opts or {['lnum'] = line_nr}

	local line_diagnostics = vim.diagnostic.get(bufnr, opts)
	if vim.tbl_isempty(line_diagnostics) then return end

	local diagnostic_message = ""
	for i, diagnostic in ipairs(line_diagnostics) do
		diagnostic_message = diagnostic_message .. string.format("%d: %s", i, diagnostic.message or "")
		print(diagnostic_message)
		if i ~= #line_diagnostics then
			diagnostic_message = diagnostic_message .. "\n"
		end
	end
	vim.api.nvim_echo({{diagnostic_message, "Normal"}}, false, {})
end

local outBuf = -1
vim.api.nvim_create_user_command("DoSql", function()
	vim.cmd("w")
	local filename = vim.fn.expand("%:p")
	local out = vim.api.nvim_exec2("!sqlcmd -U sa -P "..secrets.sqlpw.." -i "..filename, {output=true})
	local hasWindow = vim.api.nvim_call_function("bufwinnr", { outBuf }) ~= -1
	if outBuf == -1 or not hasWindow then
		vim.cmd("botright new sqlcmd output")
		outBuf = vim.api.nvim_get_current_buf()
		local win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(win, outBuf)
	end
	vim.api.nvim_set_option_value("readonly", false, {scope="local", buf=outBuf})
	vim.api.nvim_buf_set_lines(outBuf, 0, -1, false, vim.fn.split(out.output, "\n"))
	vim.api.nvim_set_option_value("readonly", true, {scope="local", buf=outBuf})
	vim.api.nvim_set_option_value("modified", false, {scope="local", buf=outBuf})
end, { desc = "Runs the current (saved) buffer through sqlcmd" })

vim.g.clipboard = {
	["name"] = "WslClipboard",
	["copy"] = {
		 ["+"] = "clip.exe",
		 ["*"] = "clip.exe",
	 },
	["paste"] = {
		 ["+"] = "powershell.exe -NoLogo -NoProfile -c Get-Clipboard",
		 ["*"] = "powershell.exe -NoLogo -NoProfile -c Get-Clipboard",
	},
	["cache_enabled"] = 0,
}

vim.diagnostic.config({
	virtual_text = false
})

cmp.setup({
	snippet = {
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

-- =============================================================================
-- lspconfig
-- =============================================================================

local lsp = {
	rust_analyzer = {},
	lua_ls = {
		on_init = function(client)
			if client.workspace_folders then
				local path = client.workspace_folders[1].name
				if vim.uv.fs_stat(path.."/.luarc.json") or vim.uv.fs_stat(path.."/.luarc.jsonc") then
					return
				end
			end
			client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
				runtime = {
					version = "LuaJIT"
				},
				workspace = {
					checkThirdParty = false,
					library = {
						vim.env.VIMRUNTIME
					}
				}
			})
		end,
		settings = {
			Lua = {}
		},
		cmd = { "lua-language-server" }
	},
	clangd = {},
	ts_ls = {
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
	},
	mojo = {},
	sourcekit = {},
	intelephense = {
		settings = {
			intelephense = {
				environment = { phpVersion = "8.4.0" }
			}
		}
	},
	sqls = {
		cmd = {"/home/giannis/junk/sqls/sqls", "-config", "/home/giannis/junk/sqls/config.yml"};
	},
	pylsp = {}
}

for k,v in pairs(lsp) do
	vim.lsp.enable(k)
	vim.lsp.config(k, v or {})
end

-- =============================================================================
-- dap
-- =============================================================================

dapui.setup()

dap.adapters.php = {
	type = "executable",
	command = "node",
	args = { os.getenv("HOME") .. "/builtjunk/vscode-php-debug/out/phpDebug.js" },
}

dap.configurations.php = {
	{
		type = "php",
		request = "launch",
		name = "Listen for Xdebug",
		port = 9003,
	}
}

-- You will likely want to reduce updatetime which affects CursorHold
-- note: this setting is global and should be set only once
vim.o.updatetime = 250
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
	group = vim.api.nvim_create_augroup("float_diagnostic", { clear = true }),
	callback = function ()
		vim.diagnostic.open_float(nil, {focus=false})
	end
})

vim.keymap.set("n", "<F5>", function() dap.continue() end)
vim.keymap.set("n", "<F10>", function() dap.step_over() end)
vim.keymap.set("n", "<F11>", function() dap.step_into() end)
vim.keymap.set("n", "<F12>", function() dap.step_out() end)
vim.keymap.set("n", "<Leader>b", function() dap.toggle_breakpoint() end)
vim.keymap.set("n", "<Leader>B", function() dap.set_breakpoint() end)
vim.keymap.set("n", "<Leader>lp", function() dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: ")) end)
vim.keymap.set("n", "<Leader>dr", function() dap.repl.open() end)
vim.keymap.set("n", "<Leader>dl", function() dap.run_last() end)
vim.keymap.set({"n", "v"}, "<Leader>dh", function()
	require("dap.ui.widgets").hover()
end)
vim.keymap.set({"n", "v"}, "<Leader>dp", function()
	require("dap.ui.widgets").preview()
end)
vim.keymap.set("n", "<Leader>df", function()
	local widgets = require("dap.ui.widgets")
	widgets.centered_float(widgets.frames)
end)
vim.keymap.set("n", "<Leader>ds", function()
	local widgets = require("dap.ui.widgets")
	widgets.centered_float(widgets.scopes)
end)
