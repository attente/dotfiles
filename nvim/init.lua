vim.o.expandtab = true
vim.o.list = true
vim.o.listchars = 'tab:•·'
vim.o.mouse = ''
vim.o.number = true
vim.o.shiftwidth = 2 -- indent size
vim.o.softtabstop = -1 -- tab size when typing, -1 = use shiftwidth
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.termguicolors = true
vim.o.updatetime = 100

vim.opt.clipboard:append("unnamedplus")

vim.cmd 'colorscheme tokyonight'

local cmp = require 'cmp'
local cmp_nvim_lsp = require 'cmp_nvim_lsp'
local lspconfig = require 'lspconfig'
local luasnip = require 'luasnip'
local nvim_treesitter = require 'nvim-treesitter.configs'
local telescope = require 'telescope.builtin'

-- nvim-cmp is a completion plugin
-- cmp-nvim-lsp is an nvim-cmp source for neovim's native lsp client
-- cmp_luasnip is an nvim-cmp source for luasnip snippets
-- luasnip is a snippet plugin
-- nvim-lspconfig is a repo of predefined lsp configs
-- nvim-treesitter is an interface to the tree-sitter parser
-- telescope is a fuzzy finder over lists

cmp.setup {
  mapping = cmp.mapping.preset.insert {
    ['<Tab>'] = cmp.mapping.confirm({ select = true }),
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp_signature_help' },
  }, {
    { name = 'nvim_lsp' },
  }, {
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
  }, {
    { name = 'path' },
  }),
  snippet = {
    expand = function (args)
      luasnip.lsp_expand(args.body)
    end,
  },
}

local capabilities = cmp_nvim_lsp.default_capabilities()

local options = { noremap = true, silent = true }
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, options)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, options)
vim.keymap.set('n', '<space>fd', telescope.diagnostics, options)
vim.keymap.set('n', '<space>ff', telescope.find_files, options)
vim.keymap.set('n', '<space>fg', telescope.live_grep, options)

local on_attach = function (client, buffer)
  local options = { noremap = true, silent = true, buffer = buffer }
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, options)
  vim.keymap.set('n', 'gd', telescope.lsp_definitions, options)
  vim.keymap.set('n', 'gr', telescope.lsp_references, options)
  vim.keymap.set('n', '<space>D', telescope.lsp_type_definitions, options)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, options)
  vim.keymap.set('n', '<space>f', function () vim.lsp.buf.format { async = true } end, options)
end

lspconfig.gopls.setup {
  capabilities = capabilities,
  on_attach = on_attach,
}

lspconfig.rust_analyzer.setup {
  capabilities = capabilities,
  on_attach = on_attach,
}

lspconfig.ts_ls.setup {
  capabilities = capabilities,
  on_attach = on_attach,
}

nvim_treesitter.setup {
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  },
}
