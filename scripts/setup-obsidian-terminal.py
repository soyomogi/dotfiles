import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


SOURCE = (
    Path(__file__).resolve().parents[1]
    / ".obsidian/plugins/terminal/keymappings.json"
)


def update_file(destination, mappings):
    settings = (
        json.loads(destination.read_text(encoding="utf-8"))
        if destination.exists()
        else {}
    )
    if settings.get("keymappings") == mappings:
        return
    settings["keymappings"] = mappings
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=destination.parent, delete=False
    ) as staged:
        temporary = Path(staged.name)
        try:
            json.dump(settings, staged, ensure_ascii=False, indent=2)
            staged.write("\n")
            staged.close()
            if destination.exists():
                shutil.copymode(destination, temporary)
            os.replace(temporary, destination)
        finally:
            temporary.unlink(missing_ok=True)


def update_running_plugin(vault, mappings):
    cli = shutil.which("obsidian") or shutil.which("Obsidian.com")
    if cli is None:
        raise SystemExit("Obsidian CLI is required for --live.")
    expected_path, desired = json.dumps(str(vault)), json.dumps(mappings)
    code = f"""
const path = window.require("node:fs").realpathSync;
if (path(app.vault.adapter.getBasePath()) !== path({expected_path})) {{
  return "wrong-vault";
}}
const settings = app.plugins.plugins.terminal?.settings;
if (typeof settings?.mutate !== "function" || typeof settings?.write !== "function") {{
  return "terminal-plugin-unavailable";
}}
const desired = {desired};
await settings.onLoaded;
if (JSON.stringify(settings.value.keymappings) !== JSON.stringify(desired)) {{
  await settings.mutate(value => {{ value.keymappings = desired; }});
  await settings.write();
}}
return "terminal-keymappings-applied";
"""
    try:
        result = subprocess.run(
            [cli, f"vault={vault.name}", "eval", f"code={code}"],
            capture_output=True,
            text=True,
            timeout=15,
        )
    except subprocess.TimeoutExpired:
        raise SystemExit("Obsidian CLI did not respond.") from None
    if result.returncode:
        raise SystemExit("Obsidian CLI could not reach the running vault.")
    status = result.stdout.strip()
    if status.removeprefix("=> ").strip() != "terminal-keymappings-applied":
        raise SystemExit(f"Obsidian could not apply Terminal key mappings: {status}")


def main():
    parser = argparse.ArgumentParser(description="Apply dotfiles' Obsidian Terminal key mappings.")
    parser.add_argument("vault", type=Path)
    parser.add_argument("--live", action="store_true", help="Apply through the open Obsidian vault.")
    args = parser.parse_args()
    vault = args.vault.resolve()
    plugin = vault / ".obsidian/plugins/terminal"
    if not (plugin / "manifest.json").is_file():
        parser.error("the specified vault does not have the Terminal plugin")
    mappings = json.loads(SOURCE.read_text(encoding="utf-8"))
    destination = plugin / "data.json"
    if args.live:
        update_running_plugin(vault, mappings)
    else:
        update_file(destination, mappings)
    if json.loads(destination.read_text(encoding="utf-8"))["keymappings"] != mappings:
        raise SystemExit("Terminal key mappings on disk do not match dotfiles.")
    print(f"Terminal key mappings applied ({len(mappings)}).")


if __name__ == "__main__":
    main()
