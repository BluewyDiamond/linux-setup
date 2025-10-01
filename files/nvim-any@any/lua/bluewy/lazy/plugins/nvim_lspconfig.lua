return {
   "neovim/nvim-lspconfig",
   lazy = false,

   config = function()
      local mason_lspconfig = require("mason-lspconfig")
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local installed_servers = mason_lspconfig.get_installed_servers()

      local override_servers = {
         rust_analyzer = function() end,
         ts_ls = function() end,
      }

      for _, server_name in ipairs(installed_servers) do
         if override_servers[server_name] then
            override_servers[server_name]()
         else
            lspconfig[server_name].setup({
               capabilities = capabilities,
            })
         end
      end

      lspconfig.fish_lsp.setup({})
      lspconfig.nushell.setup({})
   end,
}
