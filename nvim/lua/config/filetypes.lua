local M = {}

function M.setup()
    vim.filetype.add({
        filename = {
            [".importlinter"] = "cfg",
        },
        pattern = {
            -- Jenkinsfile and variants (e.g. Jenkinsfile.staging).
            ["Jenkinsfile.*"] = "groovy",
            -- Ansible inventory and playbooks.
            [".*/ansible/hosts"] = "yaml.ansible",
            [".*/playbooks/.*%.yml"] = "yaml.ansible",
            [".*/playbooks/.*%.yaml"] = "yaml.ansible",
            -- GitHub Actions workflow and composite action files.
            [".*/.github/workflows/.*%.yml"] = "yaml.ghaction",
            [".*/.github/workflows/.*%.yaml"] = "yaml.ghaction",
            [".*/.github/actions/.*%.yml"] = "yaml.ghaction",
            [".*/.github/actions/.*%.yaml"] = "yaml.ghaction",
            -- YAML example/sample/template files.
            [".*%.yml%.example"] = "yaml",
            [".*%.yml%.sample"] = "yaml",
            [".*%.yml%.ex"] = "yaml",
            [".*%.yaml%.example"] = "yaml",
            [".*%.yaml%.sample"] = "yaml",
            [".*%.yaml%.ex"] = "yaml",
            -- YAML tool dotfiles.
            ["%.?ansible%-lint"] = "yaml",
            ["%.?yamllint"] = "yaml",
            -- Python template/example files.
            [".*%.py%.template"] = "python",
            [".*%.py%.example"] = "python",
            [".*%.py%.sample"] = "python",
            [".*%.py%.ex"] = "python",
            -- INI template/example files.
            [".*%.ini%.template"] = "dosini",
            [".*%.ini%.example"] = "dosini",
            [".*%.ini%.sample"] = "dosini",
            [".*%.ini%.ex"] = "dosini",
        },
    })
end

return M
