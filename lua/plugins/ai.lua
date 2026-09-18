return {
  {
    "ravitemer/mcphub.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    build = "npm install -g mcp-hub@latest",
    opts = {},
  },
  {
    "saghen/blink.cmp",
    dependencies = {
      "Kaiser-Yang/blink-cmp-avante",
    },
    opts = {
      sources = {
        default = { "avante", "lsp", "path", "snippets", "buffer" },
        providers = {
          avante = {
            module = "blink-cmp-avante",
            name = "Avante",
            opts = {},
          },
        },
      },
    },
  },
  {
    -- NOTE: copilot.vim (not copilot.lua) on purpose. Current copilot.lua
    -- stores its token in auth.db and no longer writes hosts.json, which
    -- avante's copilot provider still requires. copilot.vim writes
    -- ~/.config/github-copilot/apps.json, which avante reads.
    -- Auth once with :Copilot setup (device flow in browser).
    "github/copilot.vim",
    init = function()
      vim.g.copilot_no_tab_map = true -- keep Tab for blink.cmp
    end,
    config = function()
      -- Mirror the omarchy Alt-key bindings copilot.lua had.
      vim.keymap.set("i", "<M-l>", 'copilot#Accept("\\<CR>")', { expr = true, replace_keycodes = false, desc = "Copilot accept" })
      vim.keymap.set("i", "<M-]>", "<Plug>(copilot-next)", { desc = "Copilot next suggestion" })
      vim.keymap.set("i", "<M-[>", "<Plug>(copilot-previous)", { desc = "Copilot previous suggestion" })
      vim.keymap.set("i", "<C-]>", "<Plug>(copilot-dismiss)", { desc = "Copilot dismiss" })
    end,
  },
  {

    "yetone/avante.nvim",
    -- RE-ENABLED (2026-09-18): default provider = openrouter (free model).
    -- copilot/gpt-5-mini returns model_not_supported on this account
    -- (deprecated/renamed or not in Copilot Free allow-list), so default is
    --   openrouter / deepseek/deepseek-v4-flash-0731:free  ($0, rate-limited)
    -- NOTE: OpenRouter has NO "Muse Spark 1.4 free". Muse on OpenRouter is
    -- only 1.1/1.2/1.3 (paid) and -contributor (ultra-cheap, trains on data).
    -- Setup: get a key at https://openrouter.ai/keys then
    --   export OPENROUTER_API_KEY="sk-or-..."   (never commit keys)
    -- Switch models anytime with :AvanteSwitchProvider (copilot kept below
    -- as fallback; needs hosts.json/apps.json bridged from auth.db).
    -- config() uses pcall so a missing key/token warns instead of
    -- aborting the whole startup with "Failed to run config".
    enabled = true,
    build = vim.fn.has("win32") ~= 0 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or "make",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    opts = {
      instructions_file = "AGENTS.md",
      provider = "openrouter",
      providers = {
        openrouter = {
          __inherited_from = "openai",
          endpoint = "https://openrouter.ai/api/v1",
          api_key_name = "OPENROUTER_API_KEY",
          model = "deepseek/deepseek-v4-flash-0731:free",
          timeout = 60000, -- free-tier models queue; allow more time
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 8192,
          },
        },
        copilot = {
          endpoint = "https://api.githubcopilot.com",
          model = "gpt-5-mini",
          proxy = nil,
          allow_insecure = false,
          timeout = 30000,
          context_window = 64000,
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 20480,
          },
        },
      },
      system_prompt = function()
        local hub = require("mcphub").get_hub_instance()
        return hub and hub:get_active_servers_prompt() or ""
      end,
      custom_tools = function()
        return {
          require("mcphub.extensions.avante").mcp_tool(),
        }
      end,
    },
    config = function(_, opts)
      local ok, err = pcall(require("avante").setup, opts)
      if not ok then
        vim.schedule(function()
          vim.notify(
            "avante setup failed (OPENROUTER_API_KEY or copilot token?): " .. tostring(err),
            vim.log.levels.WARN
          )
        end)
      end
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-mini/mini.pick",
      "nvim-telescope/telescope.nvim",
      "hrsh7th/nvim-cmp",
      "ibhagwan/fzf-lua",
      "stevearc/dressing.nvim",
      "folke/snacks.nvim",
      "nvim-tree/nvim-web-devicons",
      "github/copilot.vim",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            use_absolute_path = true,
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
}
