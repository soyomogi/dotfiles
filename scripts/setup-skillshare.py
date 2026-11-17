#!/usr/bin/env python3
"""Set up skillshare links; --install also restores and syncs skills."""

import argparse
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import sys
import tempfile


def load(path):
    metadata = json.loads(path.read_text())
    if metadata.get("version") != 1 or not isinstance(metadata.get("entries"), dict):
        raise ValueError(f"Unsupported skillshare metadata: {path}")
    return metadata


def merge(existing_path, managed_path):
    existing = load(existing_path)
    managed = load(managed_path)
    combined = existing | managed
    # Repository records win conflicts; keep additional local installations
    # and their dashboard settings so migration does not lose provenance.
    for field in ("entries", "audit_accepted", "target_overrides"):
        if field in existing or field in managed:
            combined[field] = existing.get(field, {}) | managed.get(field, {})
    if combined == managed:
        return
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=managed_path.parent,
                                         prefix=".metadata-", suffix=".tmp", delete=False) as stream:
            temporary = Path(stream.name)
            json.dump(combined, stream, indent=2, sort_keys=True)
            stream.write("\n")
        temporary.chmod(managed_path.stat().st_mode & 0o777)
        temporary.replace(managed_path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def install(path):
    # Read once: each successful install rewrites the live metadata file.
    metadata = load(path)
    for key, entry in sorted(metadata["entries"].items()):
        if not entry.get("repo_url") and not entry.get("tracked"):
            continue  # Local skills, including APM, are prepared separately.
        relative = PurePosixPath(key)
        group = entry.get("group", "")
        if group and not key.startswith(group + "/"):
            relative = PurePosixPath(group) / relative
        command = ["skillshare", "install", entry["source"], "--name", relative.name,
                   "--update", "-g"]
        if str(relative.parent) != ".":
            command += ["--into", str(relative.parent)]
        if entry.get("tracked"):
            command += ["--track"]
            revision = entry.get("branch")
        else:
            revision = entry.get("commit") or entry.get("branch")
        if revision:
            command += ["--branch", revision]
        subprocess.run(command, check=True)


def exists(path):
    return path.exists() or path.is_symlink()


def copy_missing(source, target):
    """Keep repository payloads, merging additional local files within groups."""
    for entry in source.iterdir():
        if entry.name in (".metadata.json", ".skillignore"):
            continue
        destination = target / entry.name
        if entry.is_dir() and not entry.is_symlink():
            if not exists(destination):
                destination.mkdir()
            if destination.is_dir() and not destination.is_symlink():
                copy_missing(entry, destination)
        elif not exists(destination):
            if entry.is_symlink():
                destination.symlink_to(entry.resolve(), target_is_directory=entry.is_dir())
            else:
                shutil.copy2(entry, destination)


def setup(repo, home):
    shared = repo / ".config/skillshare"
    local = home / ".config/skillshare"
    skills = shared / "skills"
    live = local / "skills"
    skills.mkdir(parents=True, exist_ok=True)
    (local / "extras").mkdir(parents=True, exist_ok=True)
    backup = None

    def link(source, target):
        nonlocal backup
        if target.is_symlink() and os.readlink(target) == str(source):
            return
        if exists(target):
            if backup is None:
                backup = Path(tempfile.mkdtemp(prefix=".dotfiles-backup.", dir=local))
                print(f"backup: {backup}")
            shutil.move(str(target), str(backup / target.name))
        target.parent.mkdir(parents=True, exist_ok=True)
        target.symlink_to(source)
        print(f"link: {target} -> {source}")

    # Link the directory: skillshare atomically replaces .metadata.json.
    if not live.is_symlink() or os.readlink(live) != str(skills):
        if (live / ".metadata.json").is_file():
            merge(live / ".metadata.json", skills / ".metadata.json")
        if live.is_dir():
            copy_missing(live, skills)
        link(skills, live)

    # Keep the Chrome registration path, sharing the Obsidian stylesheet.
    ui = local / "ui"
    if ui.is_symlink():
        ui.unlink()
    ui.mkdir(parents=True, exist_ok=True)
    extension = repo / "extensions/skillshare-ui-pink-theme"
    for name in ("manifest.json", "README.md", "LICENSE"):
        link(extension / name, ui / name)
    link(repo / ".obsidian/plugins/skillshare-ui/theme.css", ui / "theme.css")
    link(shared / "config.yaml", local / "config.yaml")
    link(shared / ".skillignore", live / ".skillignore")
    link(shared / "extras/soyomogi", local / "extras/soyomogi")


def setup_wsl(home, windows_root):
    """WSL has its own targets; Windows remains the owner of the shared source."""
    local = home / ".config/skillshare"
    local.mkdir(parents=True, exist_ok=True)
    config = local / "config.yaml"
    if not exists(config):
        config.write_text(json.dumps({
            "sources": {name: str(windows_root / name) for name in ("skills", "agents", "extras")},
            "mode": "merge", "follow_source_links": True,
            "targets": {"universal": {"skills": {
                "path": str(home / ".agents/skills"), "target_naming": "standard",
            }}},
            "ignore": [".DS_Store", ".git/", "__pycache__/"],
            "audit": {"block_threshold": "CRITICAL"},
        }, indent=2) + "\n")


def setup_windows(native_repo, restore):
    command = ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
               "-File", native_repo + "\\scripts\\setup-skillshare-windows.ps1", "-GitDir", native_repo]
    if restore:
        command.append("-Install")
    subprocess.run(command, check=True)


def setup_windows_from_wsl(repo, home, restore):
    native_repo = subprocess.check_output(["wslpath", "-w", str(repo)], text=True).strip()
    setup_windows(native_repo, restore)
    native_root = subprocess.check_output([
        "powershell.exe", "-NoProfile", "-NonInteractive", "-Command",
        'if ($env:XDG_CONFIG_HOME) { Join-Path $env:XDG_CONFIG_HOME "skillshare" } '
        'else { Join-Path $env:APPDATA "skillshare" }',
    ], text=True).strip()
    windows_root = Path(subprocess.check_output(["wslpath", "-u", native_root], text=True).strip())
    setup_wsl(home, windows_root)
    if restore:
        subprocess.run(["skillshare", "sync", "-g"], check=True)


def install_and_sync(repo, home):
    install(repo / ".config/skillshare/skills/.metadata.json")
    apm = home / "git/skills/.agents/skills"
    link = home / ".config/skillshare/skills/_apm"
    if apm.is_dir():
        if exists(link):
            if not link.is_dir() or link.resolve() != apm.resolve():
                raise ValueError(f"{link} already points elsewhere")
        else:
            subprocess.run(["skillshare", "link", str(apm), "--name", "_apm", "-g"], check=True)
    else:
        print("skip: APM skills are not prepared in ~/git/skills/.agents/skills")
    subprocess.run(["skillshare", "sync", "-g"], check=True)
    subprocess.run(["skillshare", "sync", "extras", "-g"], check=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--install", action="store_true", help="restore recorded skills and sync targets")
    args = parser.parse_args()
    try:
        repo = Path(os.environ.get("GITDIR", Path(__file__).resolve().parents[1])).expanduser().resolve()
        if args.install and sys.platform != "win32" and not shutil.which("skillshare"):
            sys.exit("skillshare is not installed")
        if sys.platform == "win32":
            setup_windows(str(repo), args.install)
        elif os.environ.get("WSL_DISTRO_NAME"):
            setup_windows_from_wsl(repo, Path.home(), args.install)
        else:
            setup(repo, Path.home())
            if args.install:
                install_and_sync(repo, Path.home())
        if not args.install:
            print("skillshare configuration ready; use --install to restore and sync skills")
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
