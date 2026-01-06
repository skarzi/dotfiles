return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"mfussenegger/nvim-dap-python",
			"leoluz/nvim-dap-go",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup()
			require("dap-go").setup()

			-- TODO(skarzi): Figure out how to use Python in the following
			-- order: uv/venv, pyenv, system.
			-- Python setup using Mason's debugpy if available
			local python_path = vim.fn.exepath("python3")
			-- Attempt to find debugpy installed via mason
			local debugpy_path = vim.fn.stdpath("data")
				.. "/mason/packages/debugpy/venv/bin/python"
			if vim.fn.filereadable(debugpy_path) == 1 then
				python_path = debugpy_path
			end

			require("dap-python").setup(python_path)

			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end

			vim.keymap.set(
				"n",
				"<leader>db",
				dap.toggle_breakpoint,
				{ desc = "Toggle Breakpoint" }
			)
			vim.keymap.set(
				"n",
				"<leader>dc",
				dap.continue,
				{ desc = "Continue" }
			)
			vim.keymap.set(
				"n",
				"<leader>di",
				dap.step_into,
				{ desc = "Step Into" }
			)
			vim.keymap.set(
				"n",
				"<leader>do",
				dap.step_over,
				{ desc = "Step Over" }
			)
			vim.keymap.set(
				"n",
				"<leader>dt",
				dap.terminate,
				{ desc = "Terminate" }
			)
		end,
	},
}
