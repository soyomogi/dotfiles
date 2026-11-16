# Skillshare Pink

An independently written light pink and lavender theme for Skillshare's web dashboard, shared by Chrome and the Obsidian Skillshare UI plugin. Its appearance is inspired by Bubble Space's Pink preset; no Bubble Space CSS, images, fonts or other assets are included. The files in this directory are MIT licensed (see LICENSE). This is an independent customization, not an official Bubble Space or Skillshare theme.

Run `bash scripts/setup-skillshare.sh` from dotfiles to link these files into `~/.config/skillshare/ui`. The canonical theme.css lives with the Obsidian plugin in `obsidian/plugins/skillshare-ui/` and is linked into the same directory. Skillshare need not be installed for this step.

## Chrome on macOS

Open `chrome://extensions`, enable Developer mode, choose **Load unpacked**, and select `~/.config/skillshare/ui` (Cmd+Shift+G opens a path entry in the file picker). This is a one-time registration. No Chrome Web Store publication is required. If your organization disables unpacked extensions, administrator approval is needed.

Only `http://127.0.0.1:19420/` and `http://localhost:19420/` and their subpages receive this CSS. The extension contains no JavaScript, telemetry, external assets or background process. For a different port, edit `include_globs` in manifest.json. Keep matches limited to the intended dashboard hosts.

After `git pull`, reload the extension in `chrome://extensions` and reload the Skillshare tab. Chrome does not automatically refresh installed content scripts when their files change.

## Obsidian on macOS

The Skillshare UI plugin reads the same CSS from `~/.config/skillshare/ui/theme.css`. It applies the stylesheet to its local dashboard Web viewer only. Change the path in the plugin settings if needed; use **Skillshare UI: Reload theme** after editing the file. Disabling the custom theme restores Skillshare's appearance.

The theme provides a fixed light palette, including when Skillshare's own Dark or Playful mode is selected. Disable the custom theme/extension to use the built-in appearance. No cache or upstream Skillshare files are changed. Tested against Skillshare 0.30.6; later UI changes may require CSS adjustments. Windows and WSL2 setup are not implemented here yet.
