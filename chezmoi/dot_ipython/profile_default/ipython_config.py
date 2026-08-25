# ViM.
c.TerminalInteractiveShell.editing_mode = "vi"
c.TerminalInteractiveShell.emacs_bindings_in_vi_insert_mode = False
c.TerminalInteractiveShell.extra_open_editor_shortcuts = True
c.TerminalInteractiveShell.prompt_includes_vi_mode = True
c.TerminalInteractiveShell.modal_cursor = True

# Auto-reloading.
c.InteractiveShellApp.exec_lines = ["%load_ext autoreload", "%autoreload 2"]

# Shell experience.
c.TerminalInteractiveShell.autoindent = True
c.TerminalIPythonApp.display_banner = False

# Code completion.
c.Completer.evaluation = "unsafe"
c.Completer.auto_close_dict_keys = True
c.Completer.jedi_compute_type_timeout = 200
