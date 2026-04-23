return {
    {
        "lervag/vimtex",
        ft = { "tex" },
        init = function()
            vim.g.vimtex_imaps_leader = "\\"
            vim.g.vimtex_view_method = "skim"
        end,
    },
    {
        "folke/zen-mode.nvim",
        cmd = "ZenMode",
        keys = {
            {
                "<leader>G",
                "<cmd>ZenMode<cr>",
                desc = "Toggle Zen Mode (distraction-free)",
            },
        },
        opts = {
            window = { width = 80 },
            plugins = { gitsigns = { enabled = true } },
        },
    },
}
