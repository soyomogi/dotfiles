# Skillshare UI for Obsidian

Desktop plugin. Requires Skillshare with `ui start` support and Obsidian's Web viewer core plugin.

Enable **Skillshare UI** in Community plugins, then use the ribbon icon or **Skillshare UI: Start server** in the command palette. Enabling or reloading the plugin does not start a server or open a tab.

Command-palette commands (also assignable to hotkeys):

- **Skillshare UI: Start server** starts or reuses the server and opens the dashboard in an Obsidian tab.
- **Skillshare UI: Stop server** stops the server on the configured port. Other clients using that server also disconnect. The dashboard tab remains open.

The command runs `skillshare ui start --no-open --global --host 127.0.0.1 --port 19420` and opens the dashboard in a Web viewer tab. An existing dashboard tab is reused, including its current page. No server starts until the command is invoked.

The executable is detected from PATH and common installation directories. Override its absolute path and port in plugin settings if needed. This plugin manages global Skillshare configuration, not vault-specific project configuration.

Closing the last dashboard tab automatically stops its server. Tabs for the same dashboard keep the server running until all are closed. Other clients connected to that server will disconnect.

Disabling the plugin leaves the server running. Stop it with **Stop server** before disabling, or from a terminal with `skillshare ui stop` when needed.

The optional custom theme reads `theme.css` in the plugin folder by default. That file is the canonical copy in dotfiles; dotfiles also links it into the Chrome extension's folder, so the plugin and the extension each apply the same CSS from the `theme.css` next to them. A relative theme path resolves against the plugin folder; `~/` and absolute paths also work. Change the CSS path or disable the theme in plugin settings. A missing CSS file leaves the standard appearance in place. **Skillshare UI: Reload theme** applies file edits to open dashboard tabs; page reloads also reapply the CSS. Other sites in Web viewer are unaffected. Unloading the plugin removes the injected stylesheet.

`main.js` is the source and distributable; no build is required. Copy `main.js`, `manifest.json` and `theme.css` to `.obsidian/plugins/skillshare-ui/` to install in another vault.

The Web viewer view type and core-plugin enabled check use Obsidian internals and may require adjustment after an Obsidian update.
